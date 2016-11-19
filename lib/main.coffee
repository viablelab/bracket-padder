BracketPadder = null

module.exports =
  activate: ->
    atom.workspace.observeTextEditors (editor) ->
      editorElement = atom.views.getView(editor)

      BracketPadder ?= require './bracket-padder'
      new BracketPadder editor, editorElement
