{
  adviseBefore, contains, findLastIndex,
  first, has, invert, keys,
} = require 'underscore-plus'

pairsToPad =
  '(': ')'
  '[': ']'
  '{': '}'

pairsToUnpad =
  '( ': ' )'
  '[ ': ' ]'
  '{ ': ' }'

defaultPairs = [
  '(', ')',
  '[', ']',
  '{', '}',
  '"', "'", '`',
]

module.exports =
class BracketPadder
  constructor: (@editor, editorElement) ->
    adviseBefore @editor, 'insertText', @insertText
    adviseBefore @editor, 'backspace', @backspace

  insertText: (text, options) =>
    return true unless text
    return true if options?.select or options?.undo is 'skip'

    closingBracket = invert(pairsToPad)[text]
    return true unless text is ' ' or closingBracket

    if @shouldPad(text)
      @editor.insertText('  ')
      @editor.moveLeft()
      return false

    if @shouldClosePair(closingBracket)
      @editor.moveRight(2)
      return false

    true

  backspace: =>
    cursor = @editor.getCursorBufferPosition()
    previousCharacters = @getPreviousCharacters(2, cursor)
    nextCharacters = @getNextCharacters(2, cursor)

    match = pairsToUnpad[previousCharacters]

    return true unless match and nextCharacters is match

    @editor.moveRight()
    @editor.backspace()
    @editor.backspace()
    false

  shouldPad: (character) =>
    return false unless character is ' '

    cursor = @editor.getCursorBufferPosition()
    previousCharacter = @getPreviousCharacters 1, cursor
    nextCharacter = @getNextCharacters 1, cursor

    match = pairsToPad[previousCharacter]
    return match and nextCharacter is match

  shouldClosePair: (character) =>
    cursor = @editor.getCursorBufferPosition()
    previousCharacters = @getPreviousCharacters(cursor.column, cursor)

    match = findLastOccurringCharacter defaultPairs, previousCharacters
    return false unless match and match is character

    nextCharacters = @getNextCharacters(2, cursor)

    return false unless first(nextCharacters) is ' '

    match = invert(pairsToPad)[nextCharacters.trim()]
    return match and match is character

  getPreviousCharacters: (count, cursor) =>
    return @editor.getTextInBufferRange([
      cursor.traverse([0, -count]),
      cursor,
    ])

  getNextCharacters: (count, cursor) =>
    return @editor.getTextInBufferRange([
      cursor,
      cursor.traverse([0, count])
    ])

findLastOccurringCharacter = (characters, string) ->
  index = string.length

  while index--
    char = string[index]

    if contains(characters, char)
      return char

  return undefined
