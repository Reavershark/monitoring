module monitoring.script;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins;
import monitoring.util.temp_file : TempFile;

import std.array : join;
import std.conv : octal, to;
import std.base64 : Base64;
import std.exception : enforce;
import std.file : getAttributes, setAttributes;
import std.process : pipeProcess, pipeShell, ProcessPipes, wait;
import std.string : capitalize;
import std.uuid : randomUUID;

import vibe.data.json : Json;
import vibe.data.bson;

@safe:

enum ScriptType
{
    Shell,
    D,
    Python,
}

final class Script : GraphNode
{
    private string m_uuid;
    private ScriptType m_type;
    private string m_source;
    private TempFile* m_tempFile;

    this(in ScriptType type, string source)
    {
        m_uuid = randomUUID.toString;
        m_type = type;
        m_source = source;
    }

    string uuid() const pure => m_uuid;
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
            m_tempFile = new TempFile(m_uuid ~ ".sh");
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
                "rdmd_" ~ cast(string) Base64.encode(cast(ubyte[]) m_uuid.dup) ~ ".d");
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
            m_tempFile = new TempFile(m_uuid ~ ".py");
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

    mixin queryMixin!(run);

    Json toJson() const
    {
        Json json = Json.emptyObject;
        json["uuid"] = uuid;
        json["type"] = type;
        json["source"] = source;
        return json;
    }

    static Script fromJson(Json json)
    {
        auto instance = new typeof(this)(
            json["type"].get!string
                .capitalize
                .to!ScriptType,
            json["source"].get!string
        );
        instance.m_uuid = json["uuid"].get!string;
        return instance;
    }
}

final class ScriptManager : GraphNode
{
    private Script[string] m_scripts;

    this()
    {
    }

    string[] listScripts() const
    {
        return m_scripts.keys;
    }

    string createScript(string type, string source)
    {
        Script script = new Script(type.capitalize.to!ScriptType, source);
        m_scripts[script.uuid] = script;
        return script.uuid;
    }

    Script getScript(string uuid)
    {
        enforce(uuid in m_scripts);
        return m_scripts[uuid];
    }

    bool removeScript(string uuid)
    {
        enforce(uuid in m_scripts);
        m_scripts.remove(uuid);
        return true;
    }

    mixin queryMixin!(
        listScripts, getScript, createScript, removeScript,
    );
}
