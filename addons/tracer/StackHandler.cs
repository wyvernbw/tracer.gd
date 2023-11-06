using Godot;
using System.Diagnostics;

public partial class StackHandler : GodotObject
{
	public string GetModulePath()
	{
		string modulePath = "unknown";
		StackTrace st = new StackTrace(true);
		if (st.FrameCount > 6)
		{
			StackFrame sf = st.GetFrame(6);
			modulePath = sf.GetFileName();
			string rootDir = ProjectSettings.GlobalizePath("res://");
			// This substring is necessary in order to remove the OS path from the module's
			// filepath.
			// i.e. remove "C:/GodotProjects/Game" from "C:/GodotProjects/Game/Scenes/Main/Main.cs"
			// ProjectSettings.LocalizePath(...) doesn't seem to work.
			modulePath = modulePath.Substring(rootDir.Length);
			// Also convert Windows-style backslashes to Godot standard forward slashes if present.
			if (modulePath.Contains("\\"))
			{
				modulePath = modulePath.Replace("\\", "/");
			}
		}
		return modulePath;
	}

	public string GetFunctionName()
	{
		string functionName = "unknown";
		StackTrace st = new StackTrace(true);
		if (st.FrameCount > 6)
		{
			StackFrame sf = st.GetFrame(6);
			functionName = sf.GetMethod().Name;
		}
		return functionName;
	}
}
