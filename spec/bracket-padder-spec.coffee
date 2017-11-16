BracketPadder = require '../lib/bracket-padder'

describe "bracket padding", ->
  [editorElement, editor] = []

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('bracket-padder')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  it 'package should be activated', ->
    actual = atom.packages.isPackageActive('bracket-padder')
    expected = true

    expect(actual).toBe expected

  it 'inserts padding between the (), [], {} pairs on <space>', ->
    testPair = (opening, closing) ->
      editor.selectAll()
      editor.delete()

      editor.insertText(opening + closing)
      unpadded = editor.buffer.getText()

      expect(unpadded).toBe(opening + closing)

      editor.setCursorBufferPosition [0, 1]

      editor.insertText(' ')
      padded = editor.buffer.getText()

      expect(padded).toBe("#{opening}  #{closing}")

      cursor = editor.getCursorBufferPosition()

      expect(cursor.column).toBe(2)

    testPair '(', ')'
    testPair '[', ']'
    testPair '{', '}'

  it 'removes padding of both sides of (), [], {} pairs on <backspace>', ->
    testPair = (opening, closing) ->
      editor.selectAll()
      editor.delete()

      editor.insertText("#{opening}  #{closing}")
      editor.setCursorBufferPosition([0, 2])

      editor.backspace()

      actual = editor.buffer.getText()
      expected = opening + closing

      expect(actual).toBe(expected)

    testPair '(', ')'
    testPair '[', ']'
    testPair '{', '}'

  it 'doesn\'t crash when changing closing character on first column', ->
    test = ->
      editor.selectAll()
      editor.delete()

      editor.insertText('{')
      editor.insertNewline()
      editor.insertText('}')

      editor.setCursorBufferPosition([1, 1])

      editor.backspace()
      editor.insertText(']')

    expect(test).not.toThrow()

  it 'autocloses padded (), [], {} pairs properly', ->
    reset = ->
      editor.selectAll()
      editor.delete()

    testPair = (opening, closing) ->
      testStrings = [
        'foo: bar'
        '"foo": "bar"'
        "'foo': 'bar'"
        '`foo`: `bar`'
        '[foo]: [bar]'
        '{foo}: {bar}'
        '(foo): (bar)'
        '"foo": ""'
      ]

      testStrings.forEach (str) ->
        reset()

        text = "#{opening} #{str} #{closing}"
        editor.insertText(text)

        editor.moveToEndOfLine()
        editor.moveLeft(2)

        editor.insertText(closing)

        expected = text
        actual = editor.buffer.getText()

        expect(actual).toBe(expected)

    testPair '(', ')'
    testPair '[', ']'
    testPair '{', '}'

  it 'skips autoclosing when cursor is within unclosed quotes', ->
    reset = ->
      editor.selectAll()
      editor.delete()

    testPair = (opening, closing) ->
      testStrings = [
        '"foo": "bar'
        "'foo: 'bar'"
        '`foo`: `bar'
      ]

      testStrings.forEach (str) ->
        reset()

        text = "#{opening} #{str} #{closing}"
        editor.insertText(text)

        editor.moveToEndOfLine()
        editor.moveLeft(2)

        editor.insertText(closing)

        expected = "#{opening} #{str}#{closing} #{closing}"
        actual = editor.buffer.getText()

        expect(actual).toBe(expected)

    testPair '(', ')'
    testPair '[', ']'
    testPair '{', '}'
