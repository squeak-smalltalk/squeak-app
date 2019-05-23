| smalltalkVersion smalltalkCIDir stonConfig monitor |
smalltalkVersion := (Smalltalk argumentAt: 1) ifNil: [''].
smalltalkCIDir := Smalltalk argumentAt: 2.
stonConfig := Smalltalk argumentAt: 3.

"Ensure FileStream stdout is open"
FileStream startUp: true.

monitor := [ [
  FileStream stdout nextPutAll: '.'.
  (Delay forMilliseconds: 5000) wait] repeat ] forkAt: 75.

"# Install smalltalkCI ========================================================"

"Metacello will automatically be bootstrapped via MetacelloStub"
[ Metacello new
  baseline: 'SmalltalkCI';
  repository: 'filetree://', smalltalkCIDir , '/repository';
  onConflict: [:ex | ex pass];
  load ] on: Warning do: [:w | w resume ].

monitor terminate.
monitor := nil.

FileStream stdout closed ifTrue: [ FileStream startUp: true ].

(Smalltalk at: #SmalltalkCI) test: stonConfig named: 'Squeak SUnit Tests'.

"Currently not reached, because SmalltalkCI>>test: closes image already"
Smalltalk snapshot: false andQuit: true.
