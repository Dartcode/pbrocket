;BASS 2.4 C/C++ header file, copyright (c) 1999-2008 Ian Luck.
;Please report bugs/suggestions/etc... To bass@un4seen.com
;
;See the BASS.CHM file for implementation documentation
;
;BASS v2.4 include for PureBasic v4.20
;C to PB adaption by Roger "Rescator" Hågensen, 27th March 2008, http://EmSai.net/

;Needed by some code in this include and various other BASS sourcecodes.
Macro LOBYTE(a) : ((a)&$ff) : EndMacro
Macro LOWORD(a) : ((a)&$ffff) : EndMacro
Macro HIWORD(a) : (((a)>>16)&$ffff) : EndMacro
Macro MAKELONG(a,b) : (((a)&$ffff)|((b)<<16)) : EndMacro

;Ready? Here we go...

#BASSVERSION=$204 ;API version

;C to PB comment:
;PureBasic has no direct match for C like typedefs, just treat these as longs instead.
;HMUSIC is a long,	MOD music handle
;HSAMPLE is a long,	sample handle
;HCHANNEL is a long,	playing sample's channel handle
;HSTREAM is a long,	sample stream handle
;HRECORD is a long,	recording handle
;HSYNC is a long,	synchronizer handle
;HDSP is a long,	DSP handle
;HFX is a long,	DX8 effect handle
;HPLUGIN is a long,	Plugin handle

;- BASS Error codes returned by BASS_GetErrorCode
#BASS_OK	             =0	 ;all is OK
#BASS_ERROR_MEM	      =1 	;memory error
#BASS_ERROR_FILEOPEN	 =2 	;can't open the file
#BASS_ERROR_DRIVER	   =3	 ;can't find a free/valid driver
#BASS_ERROR_BUFLOST	  =4	 ;the sample buffer was lost
#BASS_ERROR_HANDLE	   =5 	;invalid handle
#BASS_ERROR_FORMAT	   =6	 ;unsupported sample format
#BASS_ERROR_POSITION	 =7	 ;invalid playback position
#BASS_ERROR_INIT		    =8	 ;BASS_Init has not been successfully called
#BASS_ERROR_START	    =9	 ;BASS_Start has not been successfully called
#BASS_ERROR_ALREADY	  =14	;already initialized
#BASS_ERROR_NOCHAN	   =18	;can't get a free channel
#BASS_ERROR_ILLTYPE	  =19	;an illegal type was specified
#BASS_ERROR_ILLPARAM	 =20	;an illegal parameter was specified
#BASS_ERROR_NO3D		    =21	;no 3D support
#BASS_ERROR_NOEAX	    =22	;no EAX support
#BASS_ERROR_DEVICE	   =23	;illegal device number
#BASS_ERROR_NOPLAY	   =24	;not playing
#BASS_ERROR_FREQ		    =25	;illegal sample rate
#BASS_ERROR_NOTFILE	  =27	;the stream is not a file stream
#BASS_ERROR_NOHW		    =29	;no hardware voices available
#BASS_ERROR_EMPTY	    =31	;the MOD music has no sequence Data
#BASS_ERROR_NONET	    =32	;no internet connection could be opened
#BASS_ERROR_CREATE	   =33	;couldn't create the file
#BASS_ERROR_NOFX		    =34	;effects are not available
#BASS_ERROR_PLAYING	  =35	;the channel is playing
#BASS_ERROR_NOTAVAIL	 =37	;requested Data is not available
#BASS_ERROR_DECODE	   =38	;the channel is a "decoding channel"
#BASS_ERROR_DX		      =39	;a sufficient DirectX version is not installed
#BASS_ERROR_TIMEOUT	  =40	;connection timedout
#BASS_ERROR_FILEFORM	 =41	;unsupported file format
#BASS_ERROR_SPEAKER	  =42	;unavailable speaker
#BASS_ERROR_VERSION   =43	;invalid BASS version (used by add-ons)
#BASS_ERROR_CODEC     =44	;codec is Not available/supported
#BASS_ERROR_ENDED     =45	;the channel/file has ended
#BASS_ERROR_UNKNOWN	  =-1	;some other mystery error

;- BASS_SetConfig options
#BASS_CONFIG_BUFFER        =0
#BASS_CONFIG_UPDATEPERIOD  =1
#BASS_CONFIG_GVOL_SAMPLE   =4
#BASS_CONFIG_GVOL_STREAM   =5
#BASS_CONFIG_GVOL_MUSIC    =6
#BASS_CONFIG_CURVE_VOL     =7
#BASS_CONFIG_CURVE_PAN     =8
#BASS_CONFIG_FLOATDSP      =9
#BASS_CONFIG_3DALGORITHM   =10
#BASS_CONFIG_NET_TIMEOUT   =11
#BASS_CONFIG_NET_BUFFER    =12
#BASS_CONFIG_PAUSE_NOPLAY  =13
#BASS_CONFIG_NET_PREBUF    =15
#BASS_CONFIG_NET_PASSIVE   =18
#BASS_CONFIG_REC_BUFFER    =19
#BASS_CONFIG_NET_PLAYLIST  =21
#BASS_CONFIG_MUSIC_VIRTUAL =22
#BASS_CONFIG_VERIFY        =23
#BASS_CONFIG_UPDATETHREADS	=24

;- BASS_SetConfigPtr options
#BASS_CONFIG_NET_AGENT =16
#BASS_CONFIG_NET_PROXY =17

;- Initialization flags
#BASS_DEVICE_8BITS      =1	   ;use 8 bit resolution, Else 16 bit
#BASS_DEVICE_MONO       =2	   ;use mono, Else stereo
#BASS_DEVICE_3D         =4	   ;enable 3D functionality
#BASS_DEVICE_LATENCY    =256	 ;calculate device latency (BASS_INFO struct)
#BASS_DEVICE_CPSPEAKERS =1024 ;detect speakers via Windows control panel
#BASS_DEVICE_SPEAKERS   =2048 ;force enabling of speaker assignment
#BASS_DEVICE_NOSPEAKER  =4096 ;ignore speaker arrangement

;- DirectSound interfaces (For use With BASS_GetDSoundObject)
#BASS_OBJECT_DS    =1	;IDirectSound
#BASS_OBJECT_DS3DL	=2	;IDirectSound3DListener

;- Device info structure
Structure BASS_DEVICEINFO
	*name   ;description
	*driver ;driver
	flags.l
EndStructure

;- BASS_DEVICEINFO flags
#BASS_DEVICE_ENABLED =1
#BASS_DEVICE_DEFAULT =2
#BASS_DEVICE_INIT    =4

Structure BASS_INFO
	flags.l     ;device capabilities (DSCAPS_xxx flags)
	hwsize.l    ;size of total device hardware memory
	hwfree.l    ;size of free device hardware memory
	freesam.l   ;number of free sample slots in the hardware
	free3d.l    ;number of free 3D sample slots in the hardware
	minrate.l   ;min sample rate supported by the hardware
	maxrate.l   ;max sample rate supported by the hardware
	eax.l       ;device supports EAX? (always FALSE if BASS_DEVICE_3D was not used)
	minbuf.l    ;recommended minimum buffer length in ms (requires BASS_DEVICE_LATENCY)
	dsver.l     ;DirectSound version
	latency.l   ;delay (in ms) before start of playback (requires BASS_DEVICE_LATENCY)
	initflags.l ;BASS_Init "flags" parameter
	speakers.l  ;number of speakers available
	freq.l      ;current output rate (Vista/OSX only)
EndStructure

;- BASS_INFO flags (from DSOUND.H)
#DSCAPS_CONTINUOUSRATE  =$00000010	;supports all sample rates between min/maxrate
#DSCAPS_EMULDRIVER      =$00000020	;device does not have hardware DirectSound support
#DSCAPS_CERTIFIED       =$00000040	;device driver has been certified by Microsoft
#DSCAPS_SECONDARYMONO   =$00000100	;mono
#DSCAPS_SECONDARYSTEREO =$00000200	;stereo
#DSCAPS_SECONDARY8BIT   =$00000400	;8 bit
#DSCAPS_SECONDARY16BIT  =$00000800	;16 bit

;- Recording device info Structure
Structure BASS_RECORDINFO
	flags.l    ;device capabilities (DSCCAPS_xxx flags)
	formats.l  ;supported standard formats (WAVE_FORMAT_xxx flags)
	inputs.l   ;number of inputs
	singlein.l ;TRUE = only 1 input can be set at a time
	freq.l     ;current input rate (Vista/OSX only)
EndStructure

;- BASS_RECORDINFO flags (from DSOUND.H)
#DSCCAPS_EMULDRIVER =#DSCAPS_EMULDRIVER	;device does not have hardware DirectSound recording support
#DSCCAPS_CERTIFIED  =#DSCAPS_CERTIFIED	 ;device driver has been certified by Microsoft

;- defines for formats field of BASS_RECORDINFO (from MMSYSTEM.H)
#WAVE_FORMAT_1M08 =$00000001 ;11.025 kHz, Mono,   8-bit
#WAVE_FORMAT_1S08 =$00000002 ;11.025 kHz, Stereo, 8-bit
#WAVE_FORMAT_1M16 =$00000004 ;11.025 kHz, Mono,   16-bit
#WAVE_FORMAT_1S16 =$00000008 ;11.025 kHz, Stereo, 16-bit
#WAVE_FORMAT_2M08 =$00000010 ;22.05  kHz, Mono,   8-bit
#WAVE_FORMAT_2S08 =$00000020 ;22.05  kHz, Stereo, 8-bit
#WAVE_FORMAT_2M16 =$00000040 ;22.05  kHz, Mono,   16-bit
#WAVE_FORMAT_2S16 =$00000080 ;22.05  kHz, Stereo, 16-bit
#WAVE_FORMAT_4M08 =$00000100 ;44.1   kHz, Mono,   8-bit
#WAVE_FORMAT_4S08 =$00000200 ;44.1   kHz, Stereo, 8-bit
#WAVE_FORMAT_4M16 =$00000400 ;44.1   kHz, Mono,   16-bit
#WAVE_FORMAT_4S16 =$00000800 ;44.1   kHz, Stereo, 16-bit

;- Sample info structure
Structure BASS_SAMPLE
	freq.l     ;default playback rate
	volume.f   ;default volume (0-1)
	pan.f      ;default pan (-1=left, 0=middle, 1=right)
	flags.l    ;BASS_SAMPLE_xxx flags
	length.l   ;length (in bytes)
	max.l      ;maximum simultaneous playbacks
	origres.l  ;original resolution bits
	chans.l    ;number of channels
	mingap.l   ;minimum gap (ms) between creating channels
	mode3d.l   ;BASS_3DMODE_xxx mode
	mindist.f  ;minimum distance
	maxdist.f  ;maximum distance
	iangle.l   ;angle of inside projection cone
	oangle.l   ;angle of outside projection cone
	outvol.f   ;delta-volume outside the projection cone
	vam.l      ;voice allocation/management flags (BASS_VAM_xxx)
	priority.l ;priority (0=lowest, 0xffffffff=highest)
EndStructure

;- SAMPLE flags
#BASS_SAMPLE_8BITS     =1      ;8 bit
#BASS_SAMPLE_FLOAT     =256    ;32-bit floating-point
#BASS_SAMPLE_MONO      =2      ;mono
#BASS_SAMPLE_LOOP      =4      ;looped
#BASS_SAMPLE_3D        =8      ;3D functionality
#BASS_SAMPLE_SOFTWARE  =16     ;not using hardware mixing
#BASS_SAMPLE_MUTEMAX   =32     ;mute at max distance (3D only)
#BASS_SAMPLE_VAM       =64     ;DX7 voice allocation & management
#BASS_SAMPLE_FX        =128    ;old implementation of DX8 effects
#BASS_SAMPLE_OVER_VOL  =$10000 ;override lowest volume
#BASS_SAMPLE_OVER_POS  =$20000 ;override longest playing
#BASS_SAMPLE_OVER_DIST =$30000 ;override furthest from listener (3D only)

;- STREAM flags
#BASS_STREAM_PRESCAN  =$20000  ;enable pin-point seeking/length (MP3/MP2/MP1)
#BASS_MP3_SETPOS      =#BASS_STREAM_PRESCAN
#BASS_STREAM_AUTOFREE =$40000  ;automatically free the stream when it stop/ends
#BASS_STREAM_RESTRATE =$80000  ;restrict the download rate of internet file streams
#BASS_STREAM_BLOCK    =$100000 ;download/play internet file stream in small blocks
#BASS_STREAM_DECODE   =$200000 ;don't play the stream, only decode (BASS_ChannelGetData)
#BASS_STREAM_STATUS   =$800000 ;give server status info (HTTP/ICY tags) in DOWNLOADPROC

;- MUSIC flags
#BASS_MUSIC_FLOAT      =#BASS_SAMPLE_FLOAT
#BASS_MUSIC_MONO       =#BASS_SAMPLE_MONO
#BASS_MUSIC_LOOP       =#BASS_SAMPLE_LOOP
#BASS_MUSIC_3D         =#BASS_SAMPLE_3D
#BASS_MUSIC_FX         =#BASS_SAMPLE_FX
#BASS_MUSIC_AUTOFREE   =#BASS_STREAM_AUTOFREE
#BASS_MUSIC_DECODE     =#BASS_STREAM_DECODE
#BASS_MUSIC_PRESCAN    =#BASS_STREAM_PRESCAN ;calculate playback length
#BASS_MUSIC_CALCLEN    =#BASS_MUSIC_PRESCAN
#BASS_MUSIC_RAMP       =$200 ;normal ramping
#BASS_MUSIC_RAMPS      =$400 ;sensitive ramping
#BASS_MUSIC_SURROUND   =$800 ;surround sound
#BASS_MUSIC_SURROUND2  =$1000 ;surround sound (mode 2)
#BASS_MUSIC_FT2MOD     =$2000 ;play .MOD as FastTracker 2 does
#BASS_MUSIC_PT1MOD     =$4000 ;play .MOD as ProTracker 1 does
#BASS_MUSIC_NONINTER   =$10000 ;non-interpolated sample mixing
#BASS_MUSIC_SINCINTER  =$800000 ;sinc interpolated sample mixing
#BASS_MUSIC_POSRESET   =$8000 ;stop all notes when moving position
#BASS_MUSIC_POSRESETEX =$400000 ;stop all notes and reset bmp/etc when moving position
#BASS_MUSIC_STOPBACK   =$80000 ;stop the music on a backwards jump effect
#BASS_MUSIC_NOSAMPLE   =$100000 ;don't load the samples

;- SPEAKER assignment flags
#BASS_SPEAKER_FRONT      =$01000000 ;front speakers
#BASS_SPEAKER_REAR       =$02000000 ;rear/side speakers
#BASS_SPEAKER_CENLFE     =$03000000 ;center & LFE speakers (5.1)
#BASS_SPEAKER_REAR2      =$04000000 ;rear center speakers (7.1)
#BASS_SPEAKER_LEFT       =$10000000 ;modifier: left
#BASS_SPEAKER_RIGHT      =$20000000 ;modifier: right
Macro BASS_SPEAKER_N(n) : (n<<24) : EndMacro ;n'th pair of speakers (max 15)
#BASS_SPEAKER_FRONTLEFT  =#BASS_SPEAKER_FRONT|#BASS_SPEAKER_LEFT
#BASS_SPEAKER_FRONTRIGHT =#BASS_SPEAKER_FRONT|#BASS_SPEAKER_RIGHT
#BASS_SPEAKER_REARLEFT   =#BASS_SPEAKER_REAR|#BASS_SPEAKER_LEFT
#BASS_SPEAKER_REARRIGHT  =#BASS_SPEAKER_REAR|#BASS_SPEAKER_RIGHT
#BASS_SPEAKER_CENTER     =#BASS_SPEAKER_CENLFE|#BASS_SPEAKER_LEFT
#BASS_SPEAKER_LFE        =#BASS_SPEAKER_CENLFE|#BASS_SPEAKER_RIGHT
#BASS_SPEAKER_REAR2LEFT  =#BASS_SPEAKER_REAR2|#BASS_SPEAKER_LEFT
#BASS_SPEAKER_REAR2RIGHT =#BASS_SPEAKER_REAR2|#BASS_SPEAKER_RIGHT

#BASS_UNICODE =$80000000

#BASS_RECORD_PAUSE =$8000 ;start recording paused

;- DX7 voice allocation & management flags
#BASS_VAM_HARDWARE  =1
#BASS_VAM_SOFTWARE  =2
#BASS_VAM_TERM_TIME =4
#BASS_VAM_TERM_DIST =8
#BASS_VAM_TERM_PRIO	=16

;- BASS Structures
Structure BASS_CHANNELINFO
	freq.l 	    ;default playback rate
	chans.l     ;channels
	flags.l     ;BASS_SAMPLE/STREAM/MUSIC/SPEAKER flags
	ctype.l     ;type of channel
	origres.l   ;original resolution
	plugin.l    ;plugin handle
	sample.l    ;sample
 *filename    ;filename
EndStructure

;- BASS_CHANNELINFO types
#BASS_CTYPE_SAMPLE		         =1
#BASS_CTYPE_RECORD		         =2
#BASS_CTYPE_STREAM		         =$10000
#BASS_CTYPE_STREAM_OGG	      =$10002
#BASS_CTYPE_STREAM_MP1	      =$10003
#BASS_CTYPE_STREAM_MP2	      =$10004
#BASS_CTYPE_STREAM_MP3	      =$10005
#BASS_CTYPE_STREAM_AIFF	     =$10006
#BASS_CTYPE_STREAM_WAV	      =$40000 ;WAVE flag, LOWORD=codec
#BASS_CTYPE_STREAM_WAV_PCM	  =$50001
#BASS_CTYPE_STREAM_WAV_FLOAT	=$50003
#BASS_CTYPE_MUSIC_MOD	       =$20000
#BASS_CTYPE_MUSIC_MTM	       =$20001
#BASS_CTYPE_MUSIC_S3M	       =$20002
#BASS_CTYPE_MUSIC_XM		       =$20003
#BASS_CTYPE_MUSIC_IT		       =$20004
#BASS_CTYPE_MUSIC_MO3	       =$00100 ;MO3 flag

Structure BASS_PLUGINFORM
	ctype.l ;channel type
	*name   ;format description
	*exts   ;file extension filter (*.ext1;*.ext2;etc...)
EndStructure

Structure BASS_PLUGININFO
	version.l ;version (same form as BASS_GetVersion)
	formatc.l ;number of formats
	*formats.BASS_PLUGINFORM ;the array of formats
EndStructure

;- 3D vector (For 3D positions/velocities/orientations)
Structure BASS_3DVECTOR
	x.f ;+=right, -=left
	y.f ;+=up, -=down
	z.f ;+=front, -=behind
EndStructure

;- 3D channel modes
#BASS_3DMODE_NORMAL		 =0	;normal 3D processing
#BASS_3DMODE_RELATIVE	=1	;position is relative to the listener
#BASS_3DMODE_OFF			   =2	;no 3D processing

;- software 3D mixing algorithms (used With BASS_CONFIG_3DALGORITHM)
#BASS_3DALG_DEFAULT	=0
#BASS_3DALG_OFF		   =1
#BASS_3DALG_FULL		  =2
#BASS_3DALG_LIGHT	  =3

CompilerIf #PB_Compiler_OS=#PB_OS_Windows
 ;- EAX environments, use With BASS_SetEAXParameters
 Enumeration 0
  #EAX_ENVIRONMENT_GENERIC
  #EAX_ENVIRONMENT_PADDEDCELL
  #EAX_ENVIRONMENT_ROOM
  #EAX_ENVIRONMENT_BATHROOM
  #EAX_ENVIRONMENT_LIVINGROOM
  #EAX_ENVIRONMENT_STONEROOM
  #EAX_ENVIRONMENT_AUDITORIUM
  #EAX_ENVIRONMENT_CONCERTHALL
  #EAX_ENVIRONMENT_CAVE
  #EAX_ENVIRONMENT_ARENA
  #EAX_ENVIRONMENT_HANGAR
  #EAX_ENVIRONMENT_CARPETEDHALLWAY
  #EAX_ENVIRONMENT_HALLWAY
  #EAX_ENVIRONMENT_STONECORRIDOR
  #EAX_ENVIRONMENT_ALLEY
  #EAX_ENVIRONMENT_FOREST
  #EAX_ENVIRONMENT_CITY
  #EAX_ENVIRONMENT_MOUNTAINS
  #EAX_ENVIRONMENT_QUARRY
  #EAX_ENVIRONMENT_PLAIN
  #EAX_ENVIRONMENT_PARKINGLOT
  #EAX_ENVIRONMENT_SEWERPIPE
  #EAX_ENVIRONMENT_UNDERWATER
  #EAX_ENVIRONMENT_DRUGGED
  #EAX_ENVIRONMENT_DIZZY
  #EAX_ENVIRONMENT_PSYCHOTIC
 
  #EAX_ENVIRONMENT_COUNT			;total number of environments
 EndEnumeration
 
;EAX presets, usage: BASS_SetEAXParameters(EAX_PRESET_xxx)
 Macro EAX_PRESET_GENERIC         :#EAX_ENVIRONMENT_GENERIC,0.5F,1.493F,0.5F : EndMacro
 Macro EAX_PRESET_PADDEDCELL      :#EAX_ENVIRONMENT_PADDEDCELL,0.25F,0.1F,0.0F : EndMacro
 Macro EAX_PRESET_ROOM            :#EAX_ENVIRONMENT_ROOM,0.417F,0.4F,0.666F : EndMacro
 Macro EAX_PRESET_BATHROOM        :#EAX_ENVIRONMENT_BATHROOM,0.653F,1.499F,0.166F : EndMacro
 Macro EAX_PRESET_LIVINGROOM      :#EAX_ENVIRONMENT_LIVINGROOM,0.208F,0.478F,0.0F : EndMacro
 Macro EAX_PRESET_STONEROOM       :#EAX_ENVIRONMENT_STONEROOM,0.5F,2.309F,0.888F : EndMacro
 Macro EAX_PRESET_AUDITORIUM      :#EAX_ENVIRONMENT_AUDITORIUM,0.403F,4.279F,0.5F : EndMacro
 Macro EAX_PRESET_CONCERTHALL     :#EAX_ENVIRONMENT_CONCERTHALL,0.5F,3.961F,0.5F : EndMacro
 Macro EAX_PRESET_CAVE            :#EAX_ENVIRONMENT_CAVE,0.5F,2.886F,1.304F : EndMacro
 Macro EAX_PRESET_ARENA           :#EAX_ENVIRONMENT_ARENA,0.361F,7.284F,0.332F : EndMacro
 Macro EAX_PRESET_HANGAR          :#EAX_ENVIRONMENT_HANGAR,0.5F,10.0F,0.3F : EndMacro
 Macro EAX_PRESET_CARPETEDHALLWAY :#EAX_ENVIRONMENT_CARPETEDHALLWAY,0.153F,0.259F,2.0F : EndMacro
 Macro EAX_PRESET_HALLWAY         :#EAX_ENVIRONMENT_HALLWAY,0.361F,1.493F,0.0F : EndMacro
 Macro EAX_PRESET_STONECORRIDOR   :#EAX_ENVIRONMENT_STONECORRIDOR,0.444F,2.697F,0.638F : EndMacro
 Macro EAX_PRESET_ALLEY           :#EAX_ENVIRONMENT_ALLEY,0.25F,1.752F,0.776F : EndMacro
 Macro EAX_PRESET_FOREST          :#EAX_ENVIRONMENT_FOREST,0.111F,3.145F,0.472F : EndMacro
 Macro EAX_PRESET_CITY            :#EAX_ENVIRONMENT_CITY,0.111F,2.767F,0.224F : EndMacro
 Macro EAX_PRESET_MOUNTAINS       :#EAX_ENVIRONMENT_MOUNTAINS,0.194F,7.841F,0.472F : EndMacro
 Macro EAX_PRESET_QUARRY          :#EAX_ENVIRONMENT_QUARRY,1.0F,1.499F,0.5F : EndMacro
 Macro EAX_PRESET_PLAIN           :#EAX_ENVIRONMENT_PLAIN,0.097F,2.767F,0.224F : EndMacro
 Macro EAX_PRESET_PARKINGLOT      :#EAX_ENVIRONMENT_PARKINGLOT,0.208F,1.652F,1.5F : EndMacro
 Macro EAX_PRESET_SEWERPIPE       :#EAX_ENVIRONMENT_SEWERPIPE,0.652F,2.886F,0.25F : EndMacro
 Macro EAX_PRESET_UNDERWATER      :#EAX_ENVIRONMENT_UNDERWATER,1.0F,1.499F,0.0F : EndMacro
 Macro EAX_PRESET_DRUGGED         :#EAX_ENVIRONMENT_DRUGGED,0.875F,8.392F,1.388F : EndMacro
 Macro EAX_PRESET_DIZZY           :#EAX_ENVIRONMENT_DIZZY,0.139F,17.234F,0.666F : EndMacro
 Macro EAX_PRESET_PSYCHOTIC       :#EAX_ENVIRONMENT_PSYCHOTIC,0.486F,7.563F,0.806F : EndMacro
CompilerEndIf

;typedef DWORD (CALLBACK STREAMPROC)(HSTREAM handle, void *buffer, DWORD length, void *user);
; User stream callback function. NOTE: A stream function should obviously be as quick
;as possible, other streams (and MOD musics) can't be mixed until it's finished.
;handle : The stream that needs writing
;buffer : Buffer to write the samples in
;length : Number of bytes to write
;user   : The 'user' parameter value given when calling BASS_StreamCreate
;RETURN : Number of bytes written. Set the BASS_STREAMPROC_END flag to end
;         the stream.

#BASS_STREAMPROC_END	=$80000000	;end of user stream flag

;- special STREAMPROCs
;#STREAMPROC_DUMMY		(STREAMPROC*)0		// "dummy" stream
;#STREAMPROC_PUSH			(STREAMPROC*)-1		// push stream

;- BASS_StreamCreateFileUser file systems
#STREAMFILE_NOBUFFER		 =0
#STREAMFILE_BUFFER		   =1
#STREAMFILE_BUFFERPUSH	=2

;- User file stream callback functions
;typedef void (CALLBACK FILECLOSEPROC)(void *user);
;typedef QWORD (CALLBACK FILELENPROC)(void *user);
;typedef DWORD (CALLBACK FILEREADPROC)(void *buffer, DWORD length, void *user);
;typedef BOOL (CALLBACK FILESEEKPROC)(QWORD offset, void *user);

Structure BASS_FILEPROCS
	*close
	*length
	*read
	*seek
EndStructure

;- BASS_StreamPutFileData options
#BASS_FILEDATA_END		=0	;end & close the file

;- BASS_StreamGetFilePosition modes
#BASS_FILEPOS_CURRENT	  =0
#BASS_FILEPOS_DECODE		  =#BASS_FILEPOS_CURRENT
#BASS_FILEPOS_DOWNLOAD	 =1
#BASS_FILEPOS_END		     =2
#BASS_FILEPOS_START		   =3
#BASS_FILEPOS_CONNECTED	=4
#BASS_FILEPOS_BUFFER		  =5
#BASS_FILEPOS_SOCKET		  =6

;typedef void (CALLBACK DOWNLOADPROC)(const void *buffer, DWORD length, void *user);
;/* Internet stream download callback function.
;buffer : Buffer containing the downloaded data... NULL=end of download
;length : Number of bytes in the buffer
;user   : The 'user' parameter value given when calling BASS_StreamCreateURL */

;- BASS_ChannelSetSync types
#BASS_SYNC_POS		      =0
#BASS_SYNC_END		      =2
#BASS_SYNC_META		     =4
#BASS_SYNC_SLIDE		    =5
#BASS_SYNC_STALL		    =6
#BASS_SYNC_DOWNLOAD	  =7
#BASS_SYNC_FREE		     =8
#BASS_SYNC_SETPOS	    =11
#BASS_SYNC_MUSICPOS	  =10
#BASS_SYNC_MUSICINST	 =1
#BASS_SYNC_MUSICFX	   =3
#BASS_SYNC_OGG_CHANGE =12
#BASS_SYNC_MIXTIME	   =$40000000	;FLAG: sync at mixtime, else at playtime
#BASS_SYNC_ONETIME	   =$80000000	;FLAG: sync only once, else continuously

;typedef void (CALLBACK SYNCPROC)(HSYNC handle, DWORD channel, DWORD data, void *user);
;/* Sync callback function. NOTE: a sync callback function should be very
;quick as other syncs can't be processed until it has finished. If the sync
;is a "mixtime" sync, then other streams and MOD musics can't be mixed until
;it's finished either.
;handle : The sync that has occured
;channel: Channel that the sync occured in
;data   : Additional data associated with the sync's occurance
;user   : The 'user' parameter given when calling BASS_ChannelSetSync */

;typedef void (CALLBACK DSPPROC)(HDSP handle, DWORD channel, void *buffer, DWORD length, void *user);
;/* DSP callback function. NOTE: A DSP function should obviously be as quick as
;possible... other DSP functions, streams and MOD musics can not be processed
;until it's finished.
;handle : The DSP handle
;channel: Channel that the DSP is being applied to
;buffer : Buffer to apply the DSP to
;length : Number of bytes in the buffer
;user   : The 'user' parameter given when calling BASS_ChannelSetDSP */

;typedef BOOL (CALLBACK RECORDPROC)(HRECORD handle, const void *buffer, DWORD length, void *user);
;/* Recording callback function.
;handle : The recording handle
;buffer : Buffer containing the recorded sample data
;length : Number of bytes
;user   : The 'user' parameter value given when calling BASS_RecordStart
;RETURN : TRUE = continue recording, FALSE = stop */

;- BASS_ChannelIsActive Return values
#BASS_ACTIVE_STOPPED	=0
#BASS_ACTIVE_PLAYING	=1
#BASS_ACTIVE_STALLED	=2
#BASS_ACTIVE_PAUSED	 =3

;- Channel attributes
#BASS_ATTRIB_FREQ			          =1
#BASS_ATTRIB_VOL				          =2
#BASS_ATTRIB_PAN				          =3
#BASS_ATTRIB_EAXMIX			        =4
#BASS_ATTRIB_MUSIC_AMPLIFY	   =$100
#BASS_ATTRIB_MUSIC_PANSEP	    =$101
#BASS_ATTRIB_MUSIC_PSCALER	   =$102
#BASS_ATTRIB_MUSIC_BPM		      =$103
#BASS_ATTRIB_MUSIC_SPEED		    =$104
#BASS_ATTRIB_MUSIC_VOL_GLOBAL =$105
#BASS_ATTRIB_MUSIC_VOL_CHAN	  =$200 ;+ channel #
#BASS_ATTRIB_MUSIC_VOL_INST	  =$300 ;+ instrument #

;- BASS_ChannelGetData flags
#BASS_DATA_AVAILABLE	     =0     			 ;query how much data is buffered
#BASS_DATA_FLOAT		        =$40000000	;flag: return floating-point sample data
#BASS_DATA_FFT256	        =$80000000	;256 sample FFT
#BASS_DATA_FFT512	        =$80000001	;512 FFT
#BASS_DATA_FFT1024	       =$80000002	;1024 FFT
#BASS_DATA_FFT2048	       =$80000003	;2048 FFT
#BASS_DATA_FFT4096	       =$80000004	;4096 FFT
#BASS_DATA_FFT8192	       =$80000005 ;8192 FFT
#BASS_DATA_FFT_INDIVIDUAL =$10	      ;FFT flag: FFT for each channel, else all combined
#BASS_DATA_FFT_NOWINDOW	  =$20	      ;FFT flag: no Hanning window

;- BASS_ChannelGetTags types : what's returned
#BASS_TAG_ID3		         =0      ;ID3v1 tags : 128 byte block
#BASS_TAG_ID3V2         =1	     ;ID3v2 tags : variable length block
#BASS_TAG_OGG		         =2	     ;OGG comments : series of null-terminated UTF-8 strings
#BASS_TAG_HTTP		        =3	     ;HTTP headers : series of null-terminated ANSI strings
#BASS_TAG_ICY		         =4	     ;ICY headers : series of null-terminated ANSI strings
#BASS_TAG_META		        =5	     ;ICY metadata : ANSI string
#BASS_TAG_VENDOR		      =9	     ;OGG encoder : UTF-8 string
#BASS_TAG_LYRICS3	      =10	    ;Lyric3v2 tag : ASCII string
#BASS_TAG_RIFF_INFO	    =$100   ;RIFF/WAVE tags : series of null-terminated ANSI strings
#BASS_TAG_MUSIC_NAME		  =$10000	;MOD music name : ANSI string
#BASS_TAG_MUSIC_MESSAGE	=$10001	;MOD message : ANSI string
#BASS_TAG_MUSIC_INST		  =$10100	;+ instrument #, MOD instrument name : ANSI string
#BASS_TAG_MUSIC_SAMPLE	 =$10300	;+ sample #, MOD sample name : ANSI string

;- BASS_ChannelGetLength/GetPosition/SetPosition modes
#BASS_POS_BYTE			     =0	;byte position
#BASS_POS_MUSIC_ORDER	=1	;order.row position, MAKELONG(order,row)

;- BASS_RecordSetInput flags
#BASS_INPUT_OFF	=$10000
#BASS_INPUT_ON		=$20000

#BASS_INPUT_TYPE_MASK		  =$ff000000
#BASS_INPUT_TYPE_UNDEF		 =$00000000
#BASS_INPUT_TYPE_DIGITAL	=$01000000
#BASS_INPUT_TYPE_LINE		  =$02000000
#BASS_INPUT_TYPE_MIC			  =$03000000
#BASS_INPUT_TYPE_SYNTH		 =$04000000
#BASS_INPUT_TYPE_CD			   =$05000000
#BASS_INPUT_TYPE_PHONE		 =$06000000
#BASS_INPUT_TYPE_SPEAKER	=$07000000
#BASS_INPUT_TYPE_WAVE		  =$08000000
#BASS_INPUT_TYPE_AUX			  =$09000000
#BASS_INPUT_TYPE_ANALOG		=$0a000000

;DX8 effect types, use with BASS_ChannelSetFX
Enumeration 0
	#BASS_FX_DX8_CHORUS
	#BASS_FX_DX8_COMPRESSOR
	#BASS_FX_DX8_DISTORTION
	#BASS_FX_DX8_ECHO
	#BASS_FX_DX8_FLANGER
	#BASS_FX_DX8_GARGLE
	#BASS_FX_DX8_I3DL2REVERB
	#BASS_FX_DX8_PARAMEQ
	#BASS_FX_DX8_REVERB
EndEnumeration

Structure BASS_DX8_CHORUS
 fWetDryMix.f
 fDepth.f
 fFeedback.f
 fFrequency.f
 lWaveform.l  ;0=triangle, 1=sine
 fDelay.f
 lPhase.l     ;BASS_DX8_PHASE_xxx
EndStructure

Structure BASS_DX8_COMPRESSOR
 fGain.f
 fAttack.f
 fRelease.f
 fThreshold.f
 fRatio.f
 fPredelay.f
EndStructure

Structure BASS_DX8_DISTORTION
 fGain.f
 fEdge.f
 fPostEQCenterFrequency.f
 fPostEQBandwidth.f
 fPreLowpassCutoff.f
EndStructure

Structure BASS_DX8_ECHO
 fWetDryMix.f
 fFeedback.f
 fLeftDelay.f
 fRightDelay.f
 lPanDelay.l
EndStructure

Structure BASS_DX8_FLANGER
 fWetDryMix.f
 fDepth.f
 fFeedback.f
 fFrequency.f
 lWaveform.l	;0=triangle, 1=sine
 fDelay.f
 lPhase.l		  ;BASS_DX8_PHASE_xxx
EndStructure

Structure BASS_DX8_GARGLE
 dwRateHz.l    ;Rate of modulation in hz
 dwWaveShape.l ;0=triangle, 1=square
EndStructure

Structure BASS_DX8_I3DL2REVERB
 lRoom.l               ;[-10000, 0]      default: -1000 mB
 lRoomHF.l             ;[-10000, 0]      default: 0 mB
 flRoomRolloffFactor.f ;[0.0, 10.0]      default: 0.0
 flDecayTime.f         ;[0.1, 20.0]      default: 1.49s
 flDecayHFRatio.f      ;[0.1, 2.0]       default: 0.83
 lReflections.l        ;[-10000, 1000]   default: -2602 mB
 flReflectionsDelay.f  ;[0.0, 0.3]       default: 0.007 s
 lReverb.l             ;[-10000, 2000]   default: 200 mB
 flReverbDelay.f       ;[0.0, 0.1]       default: 0.011 s
 flDiffusion.f         ;[0.0, 100.0]     default: 100.0 %
 flDensity.f           ;[0.0, 100.0]     default: 100.0 %
 flHFReference.f       ;[20.0, 20000.0]  default: 5000.0 Hz
EndStructure

Structure BASS_DX8_PARAMEQ
 fCenter.f
 fBandwidth.f
 fGain.f
EndStructure

Structure BASS_DX8_REVERB
 fInGain.f          ;[-96.0,0.0]            default: 0.0 dB
 fReverbMix.f       ;[-96.0,0.0]            default: 0.0 db
 fReverbTime.f      ;[0.001,3000.0]         default: 1000.0 ms
 fHighFreqRTRatio.f ;[0.001,0.999]          default: 0.001
EndStructure

#BASS_DX8_PHASE_NEG_180 =0
#BASS_DX8_PHASE_NEG_90  =1
#BASS_DX8_PHASE_ZERO    =2
#BASS_DX8_PHASE_90      =3
#BASS_DX8_PHASE_180     =4

;- BASS Functions

Import "bass.lib"
 BASS_SetConfig.l(option.l,value.l)
 BASS_GetConfig.l(option.l)
 BASS_SetConfigPtr.l(option.l,value$)
 BASS_GetConfigPtr.l(option.l)
 BASS_GetVersion.l()
 BASS_ErrorGetCode.l()
 BASS_GetDeviceInfo.l(device.l,*info.BASS_DEVICEINFO)
 CompilerIf #PB_Compiler_OS=#PB_OS_Windows
  BASS_Init.l(device.l,freq.l,flags.l,win.l,*dsguid)
 CompilerElse
  BASS_Init.l(device.l,freq.l,flags.l,*win,*dsguid)
 CompilerEndIf
 BASS_SetDevice.l(device.l)
 BASS_GetDevice.l()
 BASS_Free.l()
 CompilerIf #PB_Compiler_OS=#PB_OS_Windows
  BASS_GetDSoundObject.l(object.l)
 CompilerEndIf
 BASS_GetInfo.l(*info)
 BASS_Update.l(length.l)
 BASS_GetCPU.f()
 BASS_Start.l()
 BASS_Stop.l()
 BASS_Pause.l()
 BASS_SetVolume.l(volume.f)
 BASS_GetVolume.f()
 
 BASS_PluginLoad.l(file$,flags.l)
 BASS_PluginFree.l(handle.l)
 BASS_PluginGetInfo.l(handle.l)
 
 BASS_Set3DFactors.l(distf.f,rollf.f,doppf.f)
 BASS_Get3DFactors.l(*distf,*rollf,*doppf)
 BASS_Set3DPosition.l(*pos.BASS_3DVECTOR,*vel.BASS_3DVECTOR,*front.BASS_3DVECTOR,*top.BASS_3DVECTOR)
 BASS_Get3DPosition.l(*pos.BASS_3DVECTOR,*vel.BASS_3DVECTOR,*front.BASS_3DVECTOR,*top.BASS_3DVECTOR)
 BASS_Apply3D.l()
 CompilerIf #PB_Compiler_OS=#PB_OS_Windows
  BASS_SetEAXParameters.l(env.l,vol.f,decay.f,damp.f)
  BASS_GetEAXParameters.l(*env,*vol,*decay,*damp)
 CompilerEndIf
 
 BASS_MusicLoad.l(mem.l,*file,offset.q,length.l,flags.l,freq.l)
 BASS_MusicFree.l(handle.l)
 
 BASS_SampleLoad.l(mem.l,*file,offset.q,length.l,max.l,flags.l)
 BASS_SampleCreate.l(length.l,freq.l,chans.l,max.l,flags.l)
 BASS_SampleFree.l(handle.l)
 BASS_SampleSetData.l(handle.l,*buffer)
 BASS_SampleGetData.l(handle.l,*buffer)
 BASS_SampleGetInfo.l(handle.l,*info.BASS_SAMPLE)
 BASS_SampleSetInfo.l(handle.l,*info.BASS_SAMPLE)
 BASS_SampleGetChannel.l(handle.l,onlynew.l)
 BASS_SampleGetChannels.l(handle.l,*channels)
 BASS_SampleStop.l(handle.l)
 
 BASS_StreamCreate.l(freq.l,chans.l,flags.l,*proc,*user)
 BASS_StreamCreateFile.l(mem.l,*file,offset.q,length.q,flags.l)
 BASS_StreamCreateURL.l(url.p-ascii,offset.l,flags.l,*proc,*user)
 BASS_StreamCreateFileUser.l(system.l,flags.l,*proc,*user)
 BASS_StreamFree.l(handle.l)
 BASS_StreamGetFilePosition.q(handle.l,mode.l)
 BASS_StreamPutData.l(handle.l,*buffer,length.l)
 BASS_StreamPutFileData.l(handle.l,*buffer,length.l)
 
 BASS_RecordGetDeviceInfo.l(device.l,*info.BASS_DEVICEINFO)
 BASS_RecordInit.l(device.l)
 BASS_RecordSetDevice.l(device.l)
 BASS_RecordGetDevice.l()
 BASS_RecordFree.l()
 BASS_RecordGetInfo.l(*info.BASS_RECORDINFO)
 BASS_RecordGetInputName.l(input.l)
 BASS_RecordSetInput.l(input.l,flags.l,volume.f)
 BASS_RecordGetInput.l(input.l,*volume)
 BASS_RecordStart.l(freq.l,chans.l,flags.l,*proc,*user)
 
 BASS_ChannelBytes2Seconds.d(handle.l,pos.q)
 BASS_ChannelSeconds2Bytes.q(handle.l,pos.d)
 BASS_ChannelGetDevice.l(handle.l)
 BASS_ChannelSetDevice.l(handle.l,device.l)
 BASS_ChannelIsActive.l(handle.l)
 BASS_ChannelGetInfo.l(handle.l,*info.BASS_CHANNELINFO)
 BASS_ChannelGetTags.l(handle.l,tags.l)
 BASS_ChannelFlags.l(handle.l,flags.l,mask.l)
 BASS_ChannelUpdate.l(handle.l,length.l)
 BASS_ChannelLock.l(handle.l,lock.l)
 BASS_ChannelPlay.l(handle.l,restart.l)
 BASS_ChannelStop.l(handle.l)
 BASS_ChannelPause.l(handle.l)
 BASS_ChannelSetAttribute.l(handle.l,attrib.l,value.f)
 BASS_ChannelGetAttribute.l(handle.l,attrib.l,*value)
 BASS_ChannelSlideAttribute.l(handle.l,attrib.l,value.f,time.l)
 BASS_ChannelIsSliding.l(handle.l,attrib.l)
 BASS_ChannelSet3DAttributes.l(handle.l,mode.l,min.f,max.f,iangle.l,oangle.l,outvol.f)
 BASS_ChannelGet3DAttributes.l(handle.l,*mode,*min,*max,*iangle,*oangle,*outvol)
 BASS_ChannelSet3DPosition.l(handle.l,*pos.BASS_3DVECTOR,*orient.BASS_3DVECTOR,*vel.BASS_3DVECTOR)
 BASS_ChannelGet3DPosition.l(handle.l,*pos.BASS_3DVECTOR,*orient.BASS_3DVECTOR,*vel.BASS_3DVECTOR)
 BASS_ChannelGetLength.q(handle.l,mode.l)
 BASS_ChannelSetPosition.l(handle.l,pos.q,mode.l)
 BASS_ChannelGetPosition.q(handle.l,mode.l)
 BASS_ChannelGetLevel.l(handle.l)
 BASS_ChannelGetData.l(handle.l,*buffer,length.l)
 BASS_ChannelSetSync.l(handle.l,type.l,param.q,*proc,*user)
 BASS_ChannelRemoveSync.l(handle.l,sync.l)
 BASS_ChannelSetDSP.l(handle.l,*proc,*user,priority.l)
 BASS_ChannelRemoveDSP.l(handle.l,dsp.l)
 BASS_ChannelSetLink.l(handle.l,chan.l)
 BASS_ChannelRemoveLink.l(handle.l,chan.l)
 BASS_ChannelSetFX.l(handle.l,type.l,priority.l)
 BASS_ChannelRemoveFX.l(handle.l,fx.l)
 
 BASS_FXSetParameters.l(handle.l,*params)
 BASS_FXGetParameters.l(handle.l,*params)
 BASS_FXReset.l(handle.l)
EndImport

; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 747
; FirstLine = 731
; Folding = ------
; EnableUnicode
; EnableXP
; CompileSourceDirectory