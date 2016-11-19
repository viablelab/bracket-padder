BracketPadder = require '../lib/bracket-padder'

describe "bracket padding", ->
  [editorElement, editor] = []

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open 'sample.js'

    waitsForPromise ->
      atom.packages.activatePackage 'bracket-padder'

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  it 'package should be activated', ->
    actual = atom.packages.isPackageActive 'bracket-padder'
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

      expect(padded).toBe "#{opening}  #{closing}"

      cursor = editor.getCursorBufferPosition()

      expect(cursor.column).toBe 2

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

      expect(actual).toBe expected

    testPair '(', ')'
    testPair '[', ']'
    testPair '{', '}'

  # it 'autocloses padded (), [], {} pairs', ->
  #   testPair = (opening, closing) ->
  #     editor.selectAll()
  #     editor.delete()
  #
  #     editor.insertText(opening)
  #     editor.insertText(' ')
  #     editor
  #
  #     editor.insertText("#{opening} #{closing}")
  #     editor.setCursorBufferPosition([0, 2])
  #     editor.insertText(closing)
  #
  #     actualText = editor.buffer.getText()
  #     expectedText = "#{opening} #{closing}"
  #     expect(actualText).toBe expectedText
  #
  #     actualCursorPosition = editor.getCursorBufferPosition().column
  #     expectedCursorPosition = 4
  #     expect(actualCursorPosition).toBe expectedCursorPosition
  #
  #   testPair '(', ')'
  #   testPair '[', ']'
  #   testPair '{', '}'
