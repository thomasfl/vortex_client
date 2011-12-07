require 'rubygems'
require 'vortex_client'
require 'pry'
require 'json'
require 'nokogiri'
require 'paint'

# Same script as no_right_margin.rb but with additional debug info
vortex = Vortex::Connection.new('https://www-dav.usit.uio.no', :osx_keychain => true)

no_right_margin = '<showAdditionalContent ' +
  'xmlns="http://www.uio.no/vrtx/__vrtx/ns/structured-resources">false</showAdditionalContent>'

count = 1
html_count = 1
false_count = 1
patch_count = 1
ignore_count = 1
error_count = 1
folder = '/om/organisasjon/sapp/dba/dokumentasjon/.'
# folder = '/konv/.'
vortex.find(folder, :recursive=>true)do|item|
  if(item.type == :file)
    print count.to_s + " " + item.url.path.to_s
    showAdditionalContent = ""
    if(item.url.to_s[/\.html$/])
      showAdditionalContent = item.propfind.xpath('//resources:showAdditionalContent',
                                   'resources' => 'http://www.uio.no/vrtx/__vrtx/ns/structured-resources').text

      print " " + Paint[showAdditionalContent, :green] + " : " + html_count.to_s
      html_count = html_count + 1


      # item.proppatch(no_right_margin)
      patch_count = patch_count + 1
      data = nil
      begin
        data = JSON.parse(item.content)
      rescue
        data = nil
      end
      if(data)
        data["properties"]["showAdditionalContent"] = "false"
        # data["properties"]["hideAdditionalContent"] = "true"

        ok = true
        begin
          item.content = data.to_json
        rescue
          ok = false
        end

        if(ok)
        # binding.pry
          print Paint[" * ", :yellow]
        else
          print Paint[" internal server error ", :red]
          error_count = error_count + 1
        end
      else
        print Paint[" NOT JSON Ignoring." + ignore_count.to_s, :red]
        ignore_count = ignore_count + 1
      end

      if(showAdditionalContent == "false")
        # print " false_count:" + false_count.to_s
        false_count = false_count + 1
      end
    end
    puts
    count = count + 1
   end
end
puts
puts "Sum: patched: " + patch_count.to_s
puts "Total files: " + count.to_s
puts "ignor (not json): " + ignore_count.to_s
puts "Errors: " + error_count.to_s
binding.pry

