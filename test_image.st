| smalltalkVersion smalltalkCIDir stonConfig monitor |
smalltalkVersion := (Smalltalk argumentAt: 1) ifNil: [''].
smalltalkCIDir := (FileDirectory default on: (Smalltalk argumentAt: 2)) fullName.
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

"Patch smalltalkCI to support GitHub Actions"
FileStream fileIn: smalltalkCIDir, FileDirectory slash, 'gha-support.cs'.

monitor terminate.
monitor := nil.

FileStream stdout closed ifTrue: [ FileStream startUp: true ].

(Smalltalk at: #SmalltalkCI) test: stonConfig named: 'Squeak SUnit Tests'.

"Currently not reached, because SmalltalkCI>>test: closes image already"
FileStream stdout nextPutAll: 'Closing image after testing...'; cr; flush.
Smalltalk snapshot: false andQuit: true.
