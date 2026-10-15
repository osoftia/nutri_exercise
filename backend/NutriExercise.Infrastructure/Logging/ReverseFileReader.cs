using System.Text;

namespace NutriExercise.Infrastructure.Logging;

/// <summary>
/// Reads a text file line-by-line from the end so large log files can be
/// scanned in reverse chronological order without loading them into memory.
/// Splitting on the newline byte is UTF-8 safe because <c>0x0A</c> never
/// appears inside a multi-byte sequence.
/// </summary>
public static class ReverseFileReader
{
    private const int BufferSize = 8192;
    private const byte NewLine = (byte)'\n';

    public static IEnumerable<string> ReadLines(string path, CancellationToken cancellationToken = default)
    {
        using var stream = new FileStream(
            path,
            FileMode.Open,
            FileAccess.Read,
            FileShare.ReadWrite);

        var length = stream.Length;
        if (length == 0)
        {
            yield break;
        }

        var buffer = new byte[BufferSize];
        var carry = Array.Empty<byte>();
        var position = length;

        while (position > 0)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var toRead = (int)Math.Min(BufferSize, position);
            position -= toRead;
            stream.Seek(position, SeekOrigin.Begin);

            var read = stream.Read(buffer, 0, toRead);
            var chunk = Combine(buffer, read, carry);
            var segmentEnd = chunk.Length;

            for (var index = chunk.Length - 1; index >= 0; index--)
            {
                if (chunk[index] != NewLine)
                {
                    continue;
                }

                var line = Decode(chunk, index + 1, segmentEnd - index - 1);
                if (line.Length > 0)
                {
                    yield return line;
                }

                segmentEnd = index;
            }

            carry = new byte[segmentEnd];
            Array.Copy(chunk, 0, carry, 0, segmentEnd);
        }

        var lastLine = Decode(carry, 0, carry.Length);
        if (lastLine.Length > 0)
        {
            yield return lastLine;
        }
    }

    private static byte[] Combine(byte[] buffer, int read, byte[] carry)
    {
        var chunk = new byte[read + carry.Length];
        Array.Copy(buffer, 0, chunk, 0, read);
        Array.Copy(carry, 0, chunk, read, carry.Length);

        return chunk;
    }

    private static string Decode(byte[] buffer, int offset, int count)
    {
        if (count <= 0)
        {
            return string.Empty;
        }

        return Encoding.UTF8.GetString(buffer, offset, count).TrimEnd('\r');
    }
}
