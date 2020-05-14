require 'spec_helper'

describe Polymorpheus::Interface do
  describe 'association options' do
    it 'without options' do
      create_table :drawings
      create_table :books
      create_table :binders

      expect(Drawing.new.association(:book).reflection.inverse_of).to eq(nil)
      expect(Drawing.new.association(:binder).reflection.inverse_of).to eq(nil)
      expect(Book.new.association(:drawings).reflection.inverse_of).to eq(nil)
      expect(Binder.new.association(:drawings).reflection.inverse_of).to eq(nil)
    end

    it 'with options' do
      create_table :pictures
      create_table :web_pages
      create_table :printed_works

      expect(Picture.new.association(:web_page).reflection.inverse_of.name).to eq(:pictures)
      expect(Picture.new.association(:printed_work).reflection.inverse_of.name).to eq(:pictures)
      expect(WebPage.new.association(:pictures).reflection.inverse_of.name).to eq(:web_page)
      expect(PrintedWork.new.association(:pictures).reflection.inverse_of.name).to eq(:printed_work)
    end
  end
end
