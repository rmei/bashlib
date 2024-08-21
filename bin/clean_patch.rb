#!/usr/bin/ruby

NAME = "cleanpatch"

class Hunk
  PATTERN = /^\@\@\s+\-([0-9]+),([0-9]+)\s+\+([0-9]+),([0-9]+)\s\@\@(.*)$/
  def initialize(cleaner, line=nil)
    @cleaner = cleaner
    line =~ PATTERN
    @minus_start, @minus_count, @plus_start, @plus_count = $1.to_i, $2.to_i, $3.to_i, $4.to_i
    @tail = $5
    flip_buffers
    self.collect_hunk_lines
  end

  def collect_hunk_lines
    minus_lines = @minus_count
    plus_lines = @plus_count
    while true
      line = @cleaner.getline
      if line =~ /^\+/
        plus_lines-=1
        accept line
      elsif line =~ /^\-/
        minus_lines-=1
        accept line
      elsif line =~ /^ /
        plus_lines -= 1
        minus_lines -= 1
        accept line
      else
        STDERR.print "#{NAME}: #{@filename}: malformed patch\n"
        die "#{line} (plus:#{plus_lines} minus:#{minus_lines})"
      end

      if plus_lines < 0 or minus_lines < 0
        STDERR.print "#{NAME}: #{@filename}: malformed patch\n"
        @err = 1
        p self
        @cleaner.die "plus:#{plus_lines} minus:#{minus_lines}\n"
      elsif plus_lines == 0 and minus_lines == 0
        # End of a hunk. ready for processing
        flip_buffers
        return
      end
    end
  end

  def accept(*lines)
    lines.flatten!
    lines.each { |l| @has_diff = true if /^[-+]/ =~ l }
    @working_lines.push *lines
  end

  def flip_buffers
    @lines, @working_lines = @working_lines, []
  end

  def clean
    strip_whitespace_only_diffs
    reduce_context_to 3
  end

  def reduce_context_to(context_size)
    line_count=0
    @lines.each do |l|
      if /^[-+]/ =~ l
        break
      else
        line_count +=1
        #p "#{line_count}:#{l}"
      end
    end
    if line_count > context_size
      line_count -= context_size
      @lines.slice!(0,line_count)
      @minus_count -= line_count
      @minus_start += line_count
      @plus_count -= line_count
      @plus_start += line_count
    end
    line_count=0
    @lines.reverse_each do |l|
      if /^[-+]/ =~ l
        break
      else
        line_count += 1
      end
    end
    if line_count > context_size
      line_count -= context_size
      @lines.slice!(-1 * line_count, line_count)
      @minus_count -= line_count
      @plus_count -= line_count
    end
  end

  def strip_whitespace_only_diffs
    @has_diff = false
    state=:static
    minus=[]
    plus=[]
    @lines.each do |l|
      #p "#{state} : #{l}", "#{minus},#{plus}"
      case state
        when :static then
          if l =~ /^-/
            state = :seenminus
            minus.push l
          else
            accept l
          end
        when :seenminus then
          if l =~ /^-/
            minus.push l
          elsif l =~ /^\+/
            state = :seenplus
            plus.push l
          else
            state = :static
            accept minus, l
            minus = []
          end
        when :seenplus then
          if l =~ /^\+/
            plus.push l
          else
            # done: process this
            #p "#{plus.length}:#{plus},#{minus.length}:#{minus}"
            if plus.length == minus.length
              until minus.empty?
                m_line, p_line = minus.shift(), plus.shift()
                l1 = m_line.gsub(/[-\s\r\n]+/, " ")
                l2 = p_line.gsub(/[\+\s\r\n]+/, " ")
                trim=/(?:^[\s\r\n]+)|(?:[\s\r\n]+$)/
                l1.gsub!(trim, "")
                l2.gsub!(trim, "")
                if l1 != l2
                  minus.unshift m_line
                  plus.unshift p_line
                  break
                end
                m_line.sub!(/^-/, " ")
                accept m_line
              end
            end
            accept minus, plus
            minus = []
            plus = []

            if l =~ /^-/
              state = :seenminus
              minus.push l
            else
              state = :static
              accept l
            end
          end
        else
          # bad state!
          @cleaner.die
      end
    end
    flip_buffers
  end

  def commit
    if @has_diff
      l = sprintf("@@ -%d,%d +%d,%d @@%s\n", @minus_start, @minus_count, @plus_start, @plus_count, @tail)
      @cleaner.commit l
      @lines.each do |l|
        @cleaner.commit l
      end
    end
  end
end

class Cleaner
  def initialize( filename )
    @filename = filename
    @out_lines = []
    @in_bytes = 0
    @out_bytes = 0
    @err = false
  end
  def die(msg="died")
    throw msg
  end
  def getline()
    line=@in_lines.shift
    @in_bytes += line.length
    line
  end

  def commit(line)
    @out_bytes += line.length
    @out_lines.push line
  end

  def clean()
    STDERR.print "#{NAME}: #{@filename}\n"

    if not File.file? @filename
      STDERR.print "#{@filename}: not a file\n"
      return
    end

    @in_lines = File.open(@filename).readlines

    until @in_lines.empty?
      line = getline
      if line =~ Hunk::PATTERN
        hunk = Hunk.new(self, line)
        hunk.clean
        hunk.commit
      else
        commit line
      end
    end

    @out_lines.each do |l|
      STDOUT.print "#{l}"
    end
  end
end

Cleaner.new(ARGV[0]).clean