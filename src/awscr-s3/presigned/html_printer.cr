module Awscr
  module S3
    module Presigned
      # Print a `Presigned::Form` object as RAW HTML.
      class HtmlPrinter
        def initialize(form : Form)
          @form = form
        end

        # Return the raw HTML
        def to_s(io : IO)
          io << print
        end

        # Print a `Presigned::Post` object as RAW HTML.
        def print
          br = "<br />"

          inputs = @form.fields.map do |field|
            <<-INPUT
            <input type="hidden" name="#{field.key}" value="#{field.value}" />
            INPUT
          end

          <<-HTML
          <form action="#{@form.url}" method="post" enctype="multipart/form-data">
            #{inputs.join(br)}

            <input type="file"   name="file" /> #{br}
            <input type="submit" name="submit" value="Upload" />
          </form>
          HTML
        end
      end
    end
  end
end
