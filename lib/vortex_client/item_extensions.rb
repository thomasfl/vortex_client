# Extend Net::DAV::Item

module Net
  class DAV
    class Item

      def property(xpath)
        namespaces = {'v' => "vrtx",'d' => "DAV:"}
        xml = propfind
        res = xml.xpath(xpath, namespaces)
        if(res != nil)then
          if(res.size > 0)then
            return res.first.inner_text
          else
            return res.inner_text
          end
        end
        return nil
      end

      def method_missing(method, *args, &block)
        result = property('.//v:' + method.to_s)
        if(result != nil or result != "")then
          return result
        end

        result = property('.//d:' + method.to_s)
        if(result != nil or result != "")then
          return result
        end

        result = property('.//' + method.to_s)
        if(result != nil or result != "")then
          return result
        end

        raise "Method missing: Net::DAV::Item." + method.to_s
        return nil
      end

    end
  end
end
