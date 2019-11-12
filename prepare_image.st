| smalltalkVersion releaseBuilder monitor |
smalltalkVersion := (Smalltalk argumentAt: 1) ifNil: [''].

FileStream startUp: true. "Reload stdio file handles"
SystemProgressMorph reset.
Utilities setAuthorInitials: 'buildscript'.
TranscriptStream redirectToStdOut: true.

"Avoid showing system progress bar and using graphical tools."
Project current instVarNamed: #uiManager put: DummyUIManager new.
ToolSet default: (Smalltalk at: #CommandLineToolSet).
	
MCMcmUpdater updateMissingPackages: true.
MCConfiguration upgradeIsMerge: true. "See below"

MCMcmUpdater defaultUpdateURL ifEmpty: [
	Error signal: 'There is no update URL set in the image.'].

(NetNameResolver addressForName: 'www.google.com' timeout: 1)
	ifNil: [Error signal: 'There is no internet connection available.'].

monitor := [ [
	FileStream stdout nextPutAll: '.'.
	(Delay forMilliseconds: 5000) wait] repeat ] forkAt: 75.

[[[[

Transcript show: 'Updating...'.
MCMcmUpdater default doUpdate: false.
Transcript show: 'finished.'; cr; showln: SystemVersion current printString.

Transcript showln: 'Checking for modified versions...'.
MCWorkingCopy checkModified: true.

Transcript showln: 'Recompiling...'.
Compiler recompileAll.

] on: ProgressNotification do: [:p | p resume]
] on: Warning do: [:warning | warning resume]
] on: MCNoChangesException do: [:ex | ex resume]
] on: MCMergeResolutionRequest do: [:mrr |
	mrr merger conflicts do: [:conflict |
		conflict chooseRemote].
	mrr resume: true].

"Remove obsolete classes for #testNoObsoleteClasses"
PreferenceViewRegistry removeObsolete.

"Configure image state"

monitor terminate.
monitor := nil.

Transcript showln: 'Reverting update-specific changes...'.
TranscriptStream redirectToStdOut: false.
TranscriptStream forceUpdate: true.
ToolSet default: (Smalltalk at: #StandardToolSet).
Project current instVarNamed: #uiManager put: MorphicUIManager new.
Utilities setAuthorInitials: ''.

FileStream stdout nextPutAll: 'Triggering ReleaseBuilder...'; cr; flush.
releaseBuilder := ((smalltalkVersion beginsWith: 'Etoys')
    ifTrue: [Smalltalk classNamed: 'ReleaseBuilderSqueakland']
    ifFalse: [ReleaseBuilder]).
releaseBuilder prepareEnvironment.


FileStream stdout nextPutAll: 'Exporting version information for deployment...'; cr; flush.
FileStream fileNamed: 'version.sh' do: [:strm |
	strm
		nextPutAll: ('SQUEAK_VERSION="{1}"' format: {SystemVersion current version}); lf;
		nextPutAll: ('SQUEAK_UPDATE="{1}"' format: {SystemVersion current highestUpdate}); lf;
		nextPutAll: ('IMAGE_BITS="{1}"' format: {Smalltalk image wordSize * 8}); lf;
		nextPutAll: ('IMAGE_FORMAT="{1}"' format: {Smalltalk image imageFormatVersion}); lf].

FileStream stdout nextPutAll: '[DONE]'; cr; flush.
releaseBuilder saveAndQuit.
