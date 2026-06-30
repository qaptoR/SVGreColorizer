using Godot;
using System;
using SkiaSharp;
using Svg.Skia;

public partial class SvgLoader : Node
{
    public static Image load_from_string(string svg_text, float scale_)
    {
        if (string.IsNullOrEmpty(svg_text))
        {
            GD.PrintErr("SVGLoader.load_from_string: empty SVG text");
            return null;
        }

        using var svg = new SKSvg();

        SKPicture picture;
        try
        {
            using var stream = new System.IO.MemoryStream(System.Text.Encoding.UTF8.GetBytes(svg_text));
            picture = svg.Load(stream);
        }
        catch (Exception e)
        {
            GD.PrintErr($"SVGLoader.load_from_string: failed to parse SVG - {e.Message}");
            return null;
        }

        if (picture == null)
        {
            GD.PrintErr("SVGLoader.load_from_string: SKSvg produced a null picture");
            return null;
        }

        int width = Mathf.Max(1, Mathf.RoundToInt(picture.CullRect.Width * scale_));
        int height = Mathf.Max(1, Mathf.RoundToInt(picture.CullRect.Height * scale_));

        // Force RGBA8888 + unpremultiplied so the byte layout matches Godot's
        // Image.Format.Rgba8 exactly, with no manual swizzle/unpremul step needed.
        var info = new SKImageInfo(
            width,
            height,
            SKColorType.Rgba8888,
            SKAlphaType.Unpremul
        );

        using var surface = SKSurface.Create(info);
        if (surface == null)
        {
            GD.PrintErr("SVGLoader.load_from_string: failed to create SKSurface");
            return null;
        }

        var canvas = surface.Canvas;
        canvas.Clear(SKColors.Transparent);
        canvas.Scale(scale_);
        canvas.DrawPicture(picture);
        canvas.Flush();

        using var bitmap = new SKBitmap(info);
        if (!surface.Snapshot().ReadPixels(info, bitmap.GetPixels(), info.RowBytes, 0, 0))
        {
            GD.PrintErr("SVGLoader.load_from_string: ReadPixels failed");
            return null;
        }

        int byteCount = width * height * 4;
        byte[] pixelData = new byte[byteCount];
        System.Runtime.InteropServices.Marshal.Copy(bitmap.GetPixels(), pixelData, 0, byteCount);

        var image = Image.CreateFromData(width, height, false, Image.Format.Rgba8, pixelData);
        return image;
    }
}
