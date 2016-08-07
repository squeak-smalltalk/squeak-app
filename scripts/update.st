SystemProgressMorph reset.
Utilities setAuthorInitials: 'buildscript'.
TranscriptStream redirectToStdOut: true.
TranscriptStream forceUpdate: false.

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

[[[[

Transcript showln: 'Updating...'.
config := MCMcmUpdater default updateFromRepository: repo.
config setSystemVersion.
Transcript showln: 'Update finished: ', SystemVersion current printString.

] on: ProgressNotification do: [:p |
	Transcript showln: p extraParam.
	p resume]
] on: Warning do: [:warning | warning resume]
] on: MCNoChangesException do: [:ex | ex resume]
] on: MCMergeResolutionRequest do: [:mrr |
	mrr merger conflicts do: [:conflict |
		conflict chooseRemote].
	mrr resume: true].

"Write out version information for deployment."
FileStream fileNamed: 'version.sh' do: [:strm |
	strm
		nextPutAll: ('SQUEAK_VERSION="{1}"' format: {SystemVersion current version});
		cr;
		nextPutAll: ('SQUEAK_UPDATE="{1}"' format: {SystemVersion current highestUpdate});
		cr].

"Configure image state"
Transcript showln: 'Condensing changes...'.
Smalltalk condenseChanges.

"Finish."
TranscriptStream redirectToStdOut: false.
TranscriptStream forceUpdate: true.
ToolSet default: (Smalltalk at: #StandardToolSet).
Project current instVarNamed: #uiManager put: MorphicUIManager new.
Utilities setAuthorInitials: ''.

Smalltalk snapshot: true andQuit: true.
