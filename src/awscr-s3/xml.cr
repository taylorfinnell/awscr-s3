require "xml"

module Awscr::S3
  class XML
    struct NamespacedNode
      def initialize(@node : ::XML::Node)
      end

      def string(name)
        @node.xpath("string(#{build_path(name)})", namespaces).as(String)
      end

      def array(query)
        @node.xpath(build_path(query), namespaces).as(::XML::NodeSet).each do |node|
          yield NamespacedNode.new(node)
        end
      end

      private def build_path(path)
        anywhere = false
        if path.starts_with?("//")
          anywhere = true
          path = path[2..-1]
        end

        parts = path.split("/").map do |part|
          "#{namespace}#{part}"
        end

        parts = (["/"] + parts) if anywhere

        (parts).join("/")
      end

      private def namespace
        if namespaces.empty?
          ""
        else
          "#{namespaces.keys.first}:"
        end
      end

      private def namespaces
        @node.root.not_nil!.namespaces
      end
    end

    def initialize(xml : String)
      @xml = NamespacedNode.new(::XML.parse(xml))
    end

    forward_missing_to @xml
  end
end