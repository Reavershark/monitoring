module monitoring.script;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins : graphNodeMixin;
import monitoring.util.meta : Pack;
import monitoring.util.string : b64EncodeString;
import monitoring.util.temp_file : TempFile;

import std.array : join;
import std.conv : octal, to;
import std.exception : enforce;
import std.file : getAttributes, setAttributes;
import std.process : pipeProcess, pipeShell, ProcessPipes, wait;
import std.string : capitalize;

import vibe.data.json : Json, parseJsonString;

@safe:

enum ScriptType
{
    Shell,
    D,
    Python,
}

final class Script : GraphNode
{
    private string m_uri;
    private ScriptType m_type;
    private string m_source;
    private TempFile* m_tempFile;

    this(string uri, in ScriptType type, string source)
    {
        m_uri = uri;
        m_type = type;
        m_source = source;
    }

    string uri() const pure => m_uri;
    ScriptType type() const pure => m_type;
    string source() const pure => m_source;

    Json run()
    {
        final switch (m_type)
        {
        case ScriptType.Shell:
            return runShell;
        case ScriptType.D:
            return runD;
        case ScriptType.Python:
            return runPython;
        }
    }

    private Json runShell() @trusted
    in (m_type == ScriptType.Shell)
    {
        if (m_tempFile is null)
        {
            m_tempFile = new TempFile(b64EncodeString(m_uri) ~ ".sh");
            m_tempFile.file.write(m_source);
            m_tempFile.file.flush;
            m_tempFile.file.close;
            m_tempFile.file.name.setAttributes(m_tempFile.file.name.getAttributes | octal!700);
        }

        ProcessPipes pipes = pipeShell(m_tempFile.file.name);
        int status = pipes.pid.wait;

        return Json([
            "status": Json(status),
            "stdout": Json(cast(string) pipes.stdout.byChunk(4096).join),
            "stderr": Json(cast(string) pipes.stderr.byChunk(4096).join),
        ]);
    }

    private Json runD() @trusted
    in (m_type == ScriptType.D)
    {
        if (m_tempFile is null)
        {
            m_tempFile = new TempFile(
                "rdmd_" ~ b64EncodeString(m_uri) ~ ".d");
            m_tempFile.file.write(m_source);
            m_tempFile.file.flush;
            m_tempFile.file.close;
        }

        ProcessPipes pipes = pipeProcess(["rdmd", m_tempFile.file.name]);
        int status = pipes.pid.wait;

        return Json([
            "status": Json(status),
            "stdout": Json(cast(string) pipes.stdout.byChunk(4096).join),
            "stderr": Json(cast(string) pipes.stderr.byChunk(4096).join),
        ]);
    }

    private Json runPython() @trusted
    in (m_type == ScriptType.Python)
    {
        if (m_tempFile is null)
        {
            m_tempFile = new TempFile(b64EncodeString(m_uri) ~ ".py");
            m_tempFile.file.write(m_source);
            m_tempFile.file.flush;
            m_tempFile.file.close;
        }

        ProcessPipes pipes = pipeProcess(["python3", m_tempFile.file.name]);
        int status = pipes.pid.wait;

        return Json([
            "status": Json(status),
            "stdout": Json(cast(string) pipes.stdout.byChunk(4096).join),
            "stderr": Json(cast(string) pipes.stderr.byChunk(4096).join),
        ]);
    }

    Json toJson() const
    {
        Json json = Json.emptyObject;
        json["uri"] = uri;
        json["type"] = type;
        json["source"] = source;
        return json;
    }

    static Script fromJson(Json json)
    {
        auto instance = new typeof(this)(
            json["uri"].get!string,
            json["type"].get!string
                .capitalize
                .to!ScriptType,
            json["source"].get!string,
        );
        return instance;
    }

    mixin graphNodeMixin!(
        Pack!(run),
    );
}

final class ScriptManager : GraphNode
{
    private Script[string] m_scripts;

    string[] listScripts() const
    {
        return m_scripts.keys;
    }

    void removeAllScripts()
    {
        m_scripts = null;
    }

    Script createScript(string uri, string type, string source)
    {
        enforce(uri !in m_scripts);
        Script script = new Script(uri, type.capitalize.to!ScriptType, source);
        m_scripts[uri] = script;
        return script;
    }

    Script createScriptFromJson(Json json)
    {
        enforce(json["uri"].get!string !in m_scripts);
        Script script = Script.fromJson(json);
        m_scripts[script.uri] = script;
        return script;
    }

    Script getScript(string uri)
    {
        enforce(uri in m_scripts);
        return m_scripts[uri];
    }

    void removeScript(string uri)
    {
        enforce(uri in m_scripts);
        m_scripts.remove(uri);
    }

    mixin graphNodeMixin!(
        Pack!(listScripts, getScript),
    );
}
