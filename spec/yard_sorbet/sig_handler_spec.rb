# frozen_string_literal: true

require 'yard'

RSpec.describe YARDSorbet::SigHandler do
  before do
    YARD::Registry.clear
    path = File.join(
      File.expand_path('../data', __dir__),
      'sig_handler.rb.txt'
    )
    YARD::Parser::SourceParser.parse(path)
  end

  describe 'attaching to method' do
    it 'handles signatures without arguments' do
      node = YARD::Registry.at('Signatures#sig_void')
      expect(node.docstring).to eq('comment sig_void')
    end

    it 'handles chaining' do
      node = YARD::Registry.at('Signatures#sig_override_void')
      expect(node.docstring).to eq('comment sig_override_void')
    end

    it 'handles arguments' do
      node = YARD::Registry.at('Signatures#sig_arguments')
      expect(node.docstring).to eq('comment sig_arguments')
    end

    it 'handles multiline arguments' do
      node = YARD::Registry.at('Signatures#sig_multiline_arguments')
      expect(node.docstring).to eq('comment sig_multiline_arguments')
    end

    it 'handles multiline comments' do
      node = YARD::Registry.at('Signatures#sig_multiline_comments')
      expect(node.docstring).to eq("comment sig_multiline_comments\ncomment sig_multiline_comments")
    end

    it 'handles class methods' do
      node = YARD::Registry.at('Signatures.sig_class_method')
      expect(node.docstring).to eq('comment sig_class_method')
    end

    it 'handles subclasses' do
      node = YARD::Registry.at('Subclass#method')
      expect(node.docstring).to eq('with subclass')
    end

    it 'handles classes executing code' do
      node = YARD::Registry.at('ClassWithCode#foo')
      expect(node.docstring).to eq('foo')
    end

    it 'handles nested classes' do
      node = YARD::Registry.at('Outer#outer')
      expect(node.docstring).to eq('outer method')

      node = YARD::Registry.at('Outer#outer2')
      expect(node.docstring).to eq('outer method 2')

      node = YARD::Registry.at('Outer::Inner#inner')
      expect(node.docstring).to eq('inner method')
    end

    it 'handles modules' do
      node = YARD::Registry.at('Module.foo')
      expect(node.docstring).to eq('module function')

      node = YARD::Registry.at('Module#bar')
      expect(node.docstring).to eq('module instance method')
    end

    it 'handles singleton class syntax' do
      node = YARD::Registry.at('Signatures.reopening')
      expect(node.docstring).to eq('comment reopening')
    end
  end

  describe 'sig parsing' do
    it 'parses return types' do
      node = YARD::Registry.at('SigReturn#one')
      expect(node.tag(:return).types).to eq(['Integer'])
    end

    it 'merges tags' do
      node = YARD::Registry.at('SigReturn#two')
      expect(node.tag(:return).types).to eq(['Integer'])
      expect(node.tag(:deprecated).text).to eq('do not use')
    end

    it 'overrides explicit tag' do
      node = YARD::Registry.at('SigReturn#three')
      expect(node.tag(:return).types).to eq(['Integer'])
    end

    it 'merges comment' do
      node = YARD::Registry.at('SigReturn#four')
      expect(node.tag(:return).types).to eq(['Integer'])
      expect(node.tag(:return).text).to eq('the number four')
    end

    it 'with params' do
      node = YARD::Registry.at('SigReturn#plus_one')
      expect(node.tag(:return).types).to eq(['Float'])
    end

    it 'with T syntax' do
      node = YARD::Registry.at('SigReturn#plus')
      expect(node.tag(:return).types).to eq(%w[Numeric String])
    end

    it 'with void sig' do
      node = YARD::Registry.at('SigReturn#void_method')
      expect(node.tag(:return).types).to eq(['void'])
    end

    it 'with abstract sig' do
      node = YARD::Registry.at('SigAbstract#one')
      expect(node.tag(:abstract).text).to eq('')
    end

    it 'merges abstract tag' do
      node = YARD::Registry.at('SigAbstract#two')
      expect(node.tag(:abstract).text).to eq('subclass must implement')
    end

    it 'with returns' do
      node = YARD::Registry.at('SigAbstract#with_return')
      expect(node.tag(:abstract).text).to eq('')
      expect(node.tag(:return).types).to eq(['Boolean'])
    end

    it 'with void' do
      node = YARD::Registry.at('SigAbstract#with_void')
      expect(node.tag(:abstract).text).to eq('')
      expect(node.tag(:return).types).to eq(['void'])
    end

    it 'params' do
      node = YARD::Registry.at('SigParams#foo')
      bar_tag = node.tags.find { |t| t.name == 'bar' }
      expect(bar_tag.text).to eq('the thing')
      expect(bar_tag.types).to eq(%w[String Symbol])
      baz_tag = node.tags.find { |t| t.name == 'baz' }
      expect(baz_tag.text).to eq('the other thing')
      expect(baz_tag.types).to eq(%w[String nil])
    end

    it 'block param' do
      node = YARD::Registry.at('SigParams#blk_method')
      blk_tag = node.tags.find { |t| t.name == 'blk' }
      expect(blk_tag.types).to eq(
        ['T.proc.params(arg0: String).returns(T::Array[Hash])']
      )
      expect(node.tag(:return).types).to eq(['nil'])
    end

    it 'block param with newlines' do
      node = YARD::Registry.at('SigParams#impl_blk_method')
      blk_tag = node.tags.find { |t| t.name == 'block' }
      expect(blk_tag.types).to eq(
        ['T.proc.params( model: EmailConversation, mutator: T.untyped, ).void']
      )
      expect(node.tag(:return).types).to eq(['void'])
    end

    it 'T::Array' do
      node = YARD::Registry.at('CollectionSigs#collection')
      param_tag = node.tags.find { |t| t.name == 'arr' }
      expect(param_tag.types).to eq(['Array<String>'])
    end

    it 'nested T::Array' do
      node = YARD::Registry.at('CollectionSigs#nested_collection')
      param_tag = node.tags.find { |t| t.name == 'arr' }
      expect(param_tag.types).to eq(['Array<Array<String>>'])
    end

    it 'mixed T::Array' do
      node = YARD::Registry.at('CollectionSigs#mixed_collection')
      param_tag = node.tags.find { |t| t.name == 'arr' }
      expect(param_tag.types).to eq(['Array<String, Symbol>'])
    end

    it 'T::Hash' do
      node = YARD::Registry.at('CollectionSigs#hash_method')
      expect(node.tag(:return).types).to eq(['Hash{String => Symbol}'])
    end

    it 'fixed Array' do
      node = YARD::Registry.at('CollectionSigs#fixed_array')
      expect(node.tag(:return).types).to eq(['Array(String, Integer)'])
    end

    it 'fixed Hash' do
      node = YARD::Registry.at('CollectionSigs#fixed_hash')
      expect(node.tag(:return).types).to eq(['Hash'])
      expect(node.visibility).to eq(:protected)
    end

    it 'fixed param Hash' do
      node = YARD::Registry.at('CollectionSigs#fixed_param_hash')
      param_tag = node.tags.find { |t| t.name == 'tos_acceptance' }
      expect(param_tag.types).to eq(%w[Hash nil])
    end
  end

  describe 'attributes' do
    it 'handles attr_accessor getter' do
      node = YARD::Registry.at('AttrSigs#my_accessor')
      expect(node.tag(:return).types).to eq(['String'])
    end

    it 'handles attr_accessor setter' do
      node = YARD::Registry.at('AttrSigs#my_accessor=')
      expect(node.tag(:return).types).to eq(['String'])
    end

    it 'handles attr_reader' do
      node = YARD::Registry.at('AttrSigs#my_reader')
      expect(node.tag(:return).types).to eq(['Integer'])
    end

    it 'handles attr_writer' do
      node = YARD::Registry.at('AttrSigs#my_writer=')
      expect(node.tag(:return).types).to eq(%w[Symbol nil])
    end
  end
end
