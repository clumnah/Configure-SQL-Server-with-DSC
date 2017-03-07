DECLARE @FirstfileName sysname
SELECT @FirstfileName=name FROM tempdb..sysfiles WHERE fileid = 1
IF @FirstfileName = 'tempdev'
BEGIN
	ALTER DATABASE [tempdb] MODIFY FILE (NAME=N'tempdev', NEWNAME=N'tempdev1')
	ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev1', SIZE = ##TempDBEachDataFileSize##KB , FILEGROWTH = 0 )
	ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = 1048576KB , FILEGROWTH = 1048576KB , MAXSIZE = ##TempDBLogFileSize##KB )
END
ELSE
BEGIN
	ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev1', SIZE = ##TempDBEachDataFileSize##KB , FILEGROWTH = 0 )
	ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = 1048576KB , FILEGROWTH = 1048576KB , MAXSIZE = ##TempDBLogFileSize##KB )
END

