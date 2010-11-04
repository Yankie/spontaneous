# encoding: UTF-8


require 'rdiscount'

module Spontaneous
  module FieldTypes
    class DiscountField < Base
      def process(input)
        RDiscount.new(preprocess(input), :smart, :filter_html).to_html
      end

      def preprocess(input)
        # convert lines ending with newlines into a <br/>
        # as official Markdown syntax isn't suitable for
        # casual users
        # code taken from:
        # http://github.github.com/github-flavored-markdown/
        input.gsub!(/^[\w\<][^\n]*\n+/) do |x|
          x =~ /\n{2}/ ? x : (x.strip!; x << "  \n")
        end

        # prevent foo_bar_baz from ending up with an italic word in the middle
        input.gsub!(/(^(?! {4}|\t)\w+_\w+_\w[\w_]*)/) do |x|
          x.gsub('_', '\_') if x.split('').sort.to_s[0..1] == '__'
        end
        input
      end
    end

    DiscountField.register(:discount, :markdown)
  end
end

