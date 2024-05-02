module monitoring.util.temp_file;

import std.exception : enforce;
import std.file : exists, FileException, isFile, remove, tempDir;
import std.format : f = format;
import std.stdio : File;
import std.path : buildPath;

// import vibe.core.log : logWarn;

@safe:

struct TempFile
{
    private File m_file;

    @disable this();

    this(string name)
    in (name.length)
    {
        string path = buildPath(tempDir, name);
        if (path.exists)
        {
            try
            {
                enforce(path.isFile);
                path.remove;
            }
            catch (Exception e)
                throw new Exception("TempFile path exists but can't be removed");
        }
        m_file = File(path, "w+b");
    }

    ~this()
    {
        // m_file.close;
        // try
        //     remove(m_file.name);
        // catch (FileException e)
        //     logWarn(f!`Failed to remove TempFile "%s": %s`(m_file.name, e.msg));
    }

    ref File file() return => m_file;
}
