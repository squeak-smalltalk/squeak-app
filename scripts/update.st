"Update Squeak image"
Smalltalk at: #MCMcmUpdater ifPresent: [ :updater |
  [ (updater respondsTo: #doUpdate)
    ifTrue: [ updater doUpdate ]
    ifFalse: [ (updater respondsTo: #updateFromDefaultRepository)
                ifTrue: [ updater updateFromDefaultRepository ]] ]
    on: Warning do: [ :ex | ex resume: true ]].

"Only keep the latest changes"
Smalltalk condenseChanges.

"Save and quit image"
Smalltalk at: #WorldState ifPresent: [:global |
  global addDeferredUIMessage: [
    Smalltalk at: #SmalltalkImage ifPresent: [:image |
      image current snapshot: true andQuit: true ]]].
!