FileStream stdout nextPutAll: 'Updating image...'; cr.
Smalltalk at: #MCMcmUpdater ifPresent: [ :updater |
  [ (updater respondsTo: #doUpdate)
    ifTrue: [ updater doUpdate ]
    ifFalse: [ (updater respondsTo: #updateFromDefaultRepository)
                ifTrue: [ updater updateFromDefaultRepository ]] ]
    on: Warning do: [ :ex | ex resume: true ]].

FileStream stdout nextPutAll: 'Condensing changes...'; cr.
Smalltalk condenseChanges.

Smalltalk snapshot: false andQuit: true