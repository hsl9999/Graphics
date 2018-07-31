using UnityEditor.IMGUI.Controls;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Experimental.Rendering.HDPipeline;
using UnityEditor.Experimental.Rendering.HDPipeline;

namespace UnityEditor.Experimental.Rendering.HDPipeline
{
    partial class HDReflectionProbeEditor
    {
        enum InfluenceType
        {
            Standard,
            Normal
        }

        void OnSceneGUI()
        {
            var s = m_UIState;
            var p = m_SerializedHDProbe as SerializedHDReflectionProbe;
            var o = this;

            BakeRealtimeProbeIfPositionChanged(s, p, o);

            HDReflectionProbeUI.DoShortcutKey(o);

            if (!s.sceneViewEditing)
                return;
            
            var mat = Matrix4x4.TRS(p.targetLegacy.transform.position, p.targetLegacy.transform.rotation, Vector3.one);

            EditorGUI.BeginChangeCheck();

            switch (EditMode.editMode)
            {
                // Influence editing
                case EditMode.SceneViewEditMode.ReflectionProbeBox:
                    InfluenceVolumeUI.DrawHandles_EditBase(s.influenceVolume, p.target.influenceVolume, o, mat, p.target);
                    break;
                // Influence fade editing
                case EditMode.SceneViewEditMode.GridBox:
                    InfluenceVolumeUI.DrawHandles_EditInfluence(s.influenceVolume, p.target.influenceVolume, o, mat, p.target);
                    break;
                // Influence normal fade editing
                case EditMode.SceneViewEditMode.Collider:
                    InfluenceVolumeUI.DrawHandles_EditInfluenceNormal(s.influenceVolume, p.target.influenceVolume, o, mat, p.target);
                    break;
                // Origin editing
                case EditMode.SceneViewEditMode.ReflectionProbeOrigin:
                    Handle_OriginEditing(s, p, o);
                    break;
            }

            if (EditorGUI.EndChangeCheck())
                Repaint();
        }

        static void Handle_OriginEditing(HDReflectionProbeUI s, SerializedHDReflectionProbe sp, Editor o)
        {
            var p = (ReflectionProbe)sp.serializedLegacyObject.targetObject;
            var transformPosition = p.transform.position;
            var size = p.size;

            EditorGUI.BeginChangeCheck();
            var newPostion = Handles.PositionHandle(transformPosition, HDReflectionProbeEditorUtility.GetLocalSpaceRotation(p));

            var changed = EditorGUI.EndChangeCheck();

            if (changed || s.oldLocalSpace != HDReflectionProbeEditorUtility.GetLocalSpace(p))
            {
                var localNewPosition = s.oldLocalSpace.inverse.MultiplyPoint3x4(newPostion);

                var b = new Bounds(p.center, size);
                localNewPosition = b.ClosestPoint(localNewPosition);

                Undo.RecordObject(p.transform, "Modified Reflection Probe Origin");
                p.transform.position = s.oldLocalSpace.MultiplyPoint3x4(localNewPosition);

                Undo.RecordObject(p, "Modified Reflection Probe Origin");
                p.center = HDReflectionProbeEditorUtility.GetLocalSpace(p).inverse.MultiplyPoint3x4(s.oldLocalSpace.MultiplyPoint3x4(p.center));

                EditorUtility.SetDirty(p);

                s.UpdateOldLocalSpace(p);
            }
        }
    }
}
