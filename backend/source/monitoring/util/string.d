module monitoring.util.string;

import std.base64 : Base64;

string b64EncodeString(in string s)
{
    return Base64.encode(cast(ubyte[]) s);
}
