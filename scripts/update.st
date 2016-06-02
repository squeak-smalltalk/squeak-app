FileStream stdout nextPutAll: 'Updating image...'; cr.
[ MCMcmUpdater updateFromDefaultRepository ]
    on: Warning do: [ :ex | ex resume: true ]].

FileStream stdout nextPutAll: 'Condensing changes...'; cr.
Smalltalk condenseChanges.

Smalltalk snapshot: false andQuit: true