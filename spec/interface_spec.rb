require 'spec_helper'

describe Polymorpheus::Interface do
  describe 'association options' do
    it 'without options' do
      create_table :drawings
      create_table :books
      create_table :binders

      Drawing.new.association(:book).reflection.inverse_of.should == nil
      Drawing.new.association(:binder).reflection.inverse_of.should == nil
      Book.new.association(:drawings).reflection.inverse_of.should == nil
      Binder.new.association(:drawings).reflection.inverse_of.should == nil
    end

    it 'with options' do
      create_table :pictures
      create_table :web_pages
      create_table :printed_works

      Picture.new.association(:web_page).reflection.inverse_of.name.should == :pictures
      Picture.new.association(:printed_work).reflection.inverse_of.name.should == :pictures
      WebPage.new.association(:pictures).reflection.inverse_of.name.should == :web_page
      PrintedWork.new.association(:pictures).reflection.inverse_of.name.should == :printed_work
    end
  end
end
