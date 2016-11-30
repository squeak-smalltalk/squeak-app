| smalltalkVersion |
smalltalkVersion := (Smalltalk argumentAt: 1) ifNil: [''].

SystemProgressMorph reset.
Utilities setAuthorInitials: 'buildscript'.
TranscriptStream redirectToStdOut: true.

"Avoid showing system progress bar and using graphical tools."
Project current instVarNamed: #uiManager put: DummyUIManager new.
ToolSet default: (Smalltalk at: #CommandLineToolSet).

"Patch bug in DummyUIManager."
DummyUIManager
	compile: 'informUserDuring: aBlock\	aBlock value: Association new' withCRs
	classified: 'ui requests'.
	
MCMcmUpdater updateMissingPackages: true.
MCConfiguration upgradeIsMerge: true. "See below"

MCMcmUpdater defaultUpdateURL ifEmpty: [
	Error signal: 'There is no update URL set in the image.'].

repo := MCRepositoryGroup default repositories
	detect: [:r | r description = MCMcmUpdater defaultUpdateURL]
	ifNone: [Error signal: 'The update repository does not exist.'].

(NetNameResolver addressForName: 'www.google.com' timeout: 1)
	ifNil: [Error signal: 'There is no internet connection available.'].

"Flush all caches. If a previous download failed this is often helpful"
MCFileBasedRepository flushAllCaches.

monitor := [ [
	FileStream stdout nextPutAll: '.'.
	(Delay forMilliseconds: 5000) wait] repeat ] forkAt: 75.

[[[[

Transcript show: 'Updating...'.
"XXX HACK work around updater bug"
[(Installer squeak
	project: 'trunk';
	addPackage: 'SmallLand-ColorTheme-fbs.6.mcz')
	mcThing] on: Error do: [:ex|].
config := MCMcmUpdater default updateFromRepository: repo.
config setSystemVersion.
Transcript show: 'finished.'; cr; showln: SystemVersion current printString.

Transcript showln: 'Checking for modified versions...'.
MCWorkingCopy checkModified: true.

] on: ProgressNotification do: [:p | p resume]
] on: Warning do: [:warning | warning resume]
] on: MCNoChangesException do: [:ex | ex resume]
] on: MCMergeResolutionRequest do: [:mrr |
	mrr merger conflicts do: [:conflict |
		conflict chooseRemote].
	mrr resume: true].

"Configure image state"
Transcript showln: 'Condensing changes...'.
Smalltalk condenseChanges.

monitor terminate.
monitor := nil.

"Revert the update-specific changes."
TranscriptStream redirectToStdOut: false.
TranscriptStream forceUpdate: true.
ToolSet default: (Smalltalk at: #StandardToolSet).
Project current instVarNamed: #uiManager put: MorphicUIManager new.
Utilities setAuthorInitials: ''.

"Finish."
((smalltalkVersion beginsWith: 'Etoys')
    ifTrue: [Smalltalk classNamed: 'ReleaseBuilderSqueakland']
    ifFalse: [ReleaseBuilder])
        prepareEnvironment.

"Write out version information for deployment."
FileStream fileNamed: 'version.sh' do: [:strm |
	strm
		nextPutAll: ('SQUEAK_VERSION="{1}"' format: {SystemVersion current version}); lf;
		nextPutAll: ('SQUEAK_UPDATE="{1}"' format: {SystemVersion current highestUpdate}); lf;
		nextPutAll: ('IMAGE_BITS="{1}"' format: {Smalltalk image wordSize * 8}); lf;
		nextPutAll: ('IMAGE_FORMAT="{1}"' format: {Smalltalk image imageFormatVersion}); lf].

Smalltalk snapshot: true andQuit: true.
