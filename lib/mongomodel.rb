#searches all files in models directory and creates notation suitable for http://yuml.me/
class Uml

  def self.create_yuml_output
    Dir.glob('./models/*.rb') do |rb_file|
      text=File.open(rb_file).read
      text.gsub!(/\r\n?/, "\n")
      klass = ""
      text.each_line do |line|
        if match = line.match(/class (\w+)( < .*)?/i)
          klass = match.captures[0]
          parent_class = match.captures[1]
          if parent_class
            parent_class = parent_class.strip.gsub(/</, '').strip
            print "[#{parent_class}]^-[#{klass}]\n"
          end
        end

        if line.strip.start_with?('many') || line.strip.start_with?('one')
          if match = line.match(/.*:class_name => "(\w+)"/)
            to_klass = match.captures[0]
          end

          if line.strip.start_with?('many')
            print "[#{klass}] -> [#{to_klass}]\n"
          end
          if line.strip.start_with?('one')
            print "[#{klass}] - [#{to_klass}]\n"
          end
        end
      end
    end
  end
end
