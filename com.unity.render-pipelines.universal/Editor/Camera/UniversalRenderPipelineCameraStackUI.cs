using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEditor.SceneManagement;
using UnityEditorInternal;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal
{
    internal class UniversalRenderPipelineCameraStackUI
    {
        static readonly List<CameraRenderType> s_ValidCameraTypes = new List<CameraRenderType>
        {
            CameraRenderType.Overlay
            // Add here the supported types of cameras
        };

        static class Styles
        {
            public static readonly Texture2D errorIcon =
                EditorGUIUtility.Load("icons/console.erroricon.sml.png") as Texture2D;

            public static readonly GUIStyle errorStyle = new GUIStyle(EditorStyles.label)
            {
                padding = new RectOffset { left = -16 }
            };

            public static readonly Dictionary<CameraRenderType, GUIContent> typeNotSupportedMessage = Enum.GetValues(typeof(CameraRenderType))
                .Cast<CameraRenderType>()
                .Where(cameraRenderType => !s_ValidCameraTypes.Contains(cameraRenderType))
                .ToDictionary(cameraRenderType => cameraRenderType, cameraRenderType => EditorGUIUtility.TrTextContent(cameraRenderType.GetName(), cameraRenderType.GetName() + " is not supported", errorIcon));

            public static readonly GUIContent[] camerasToAddNotFound = { EditorGUIUtility.TrTextContent("Could not find suitable cameras") };

            public static readonly string validTypes = $"Valid types are:{Environment.NewLine}{string.Join("\n", s_ValidCameraTypes.Select(i => $"  - {i}"))}";
        }

        readonly Camera m_Camera;
        readonly ReorderableList m_LayerList;
        readonly SerializedObject m_SerializedObject;
        readonly SerializedProperty m_SerializedPropertyElements;

        List<Camera> errorCameras { get; } = new List<Camera>();

        bool CanRemove(ReorderableList list)
        {
            // As the list can delete the last item, allow the delete action if there is at least one item
            return m_SerializedPropertyElements.arraySize > 0;
        }

        bool GetCameraAtIndex(int index, ref Camera foundCamera)
        {
            // Check that the index is between the bounds
            if (index < 0 || index > m_SerializedPropertyElements.arraySize - 1)
                return false;

            // Return the camera on that index
            foundCamera = m_SerializedPropertyElements
                .GetArrayElementAtIndex(index)
                .objectReferenceValue as Camera;

            return true;
        }

        void RemoveCameraByIndexFromList(int selectedIndex)
        {
            Camera cam = null;
            if (!GetCameraAtIndex(selectedIndex, ref cam))
                return;

            // If the deleted camera had errors, the camera should be deleted from the cameras with errors
            if (errorCameras.Contains(cam))
                errorCameras.Remove(cam);

            // Delete the camera from the object
            m_SerializedPropertyElements.DeleteArrayElementAtIndex(selectedIndex);
        }

        void RemoveCameraFromList(ReorderableList list)
        {
            var selectedIndices = list.selectedIndices;

            if (selectedIndices.Any())
            {
                // Remove the selected indices on the list
                foreach (int selectedIndex in selectedIndices)
                    RemoveCameraByIndexFromList(selectedIndex);
            }
            else
            {
                // Nothing has selected, remove the last item on the list
                ReorderableList.defaultBehaviours.DoRemoveButton(list);
            }

            m_SerializedObject.ApplyModifiedProperties();
        }

        List<Camera> availableCamerasToAdd { get; } = new List<Camera>();

        void AddCameraToCameraList(Rect rect, ReorderableList list)
        {
            // Need to do clear the list here otherwise the menu just fills up with more and more entries
            availableCamerasToAdd.Clear();

            var allCameras = FindCamerasToReference(m_Camera.gameObject);
            foreach (var camera in allCameras)
            {
                var component = camera.gameObject.GetComponent<UniversalAdditionalCameraData>();
                if (component == null)
                    continue;

                if (s_ValidCameraTypes.Contains(component.renderType))
                {
                    availableCamerasToAdd.Add(camera);
                }
            }

            var names = (availableCamerasToAdd.Any())
                ? availableCamerasToAdd
                    .Select((camera, i) => new GUIContent((i + 1) + " " + availableCamerasToAdd[i].name))
                    .ToArray()
                : Styles.camerasToAddNotFound;

            EditorUtility.DisplayCustomMenu(rect, names, -1, AddCameraToCameraListMenuSelected, null);
        }

        void AddCameraToCameraListMenuSelected(object userData, string[] options, int selected)
        {
            if (!availableCamerasToAdd.Any())
                return;

            var length = m_SerializedPropertyElements.arraySize;
            ++m_SerializedPropertyElements.arraySize;
            m_SerializedObject.ApplyModifiedProperties();
            m_SerializedPropertyElements.GetArrayElementAtIndex(length).objectReferenceValue = availableCamerasToAdd[selected];
            m_SerializedObject.ApplyModifiedProperties();
        }

        // Modified version of StageHandle.FindComponentsOfType<T>()
        // This version more closely represents unity object referencing restrictions.
        // I added these restrictions:
        // - Can not reference scene object outside scene
        // - Can not reference cross scenes
        // - Can reference child objects if it is prefab
        Camera[] FindCamerasToReference(GameObject gameObject)
        {
            var scene = gameObject.scene;

            var inScene = !EditorUtility.IsPersistent(m_Camera) || scene.IsValid();
            var inPreviewScene = EditorSceneManager.IsPreviewScene(scene) && scene.IsValid();
            var inCurrentScene = !EditorUtility.IsPersistent(m_Camera) && scene.IsValid();

            Camera[] cameras = Resources.FindObjectsOfTypeAll<Camera>();
            if (!cameras.Any())
                return Array.Empty<Camera>();

            if (!inScene)
            {
                return cameras
                    .Where(camera => camera.transform.IsChildOf(gameObject.transform))
                    .ToArray();
            }

            if (inPreviewScene)
            {
                return cameras
                    .Where(camera => camera.gameObject.scene == scene)
                    .ToArray();
            }

            if (inCurrentScene)
            {
                return cameras
                    .Where(camera =>
                        !EditorUtility.IsPersistent(camera) &&
                        !EditorSceneManager.IsPreviewScene(camera.gameObject.scene) && camera.gameObject.scene == scene)
                    .ToArray();
            }

            return Array.Empty<Camera>();
        }

        void SelectElement(ReorderableList list)
        {
            var element = m_SerializedPropertyElements.GetArrayElementAtIndex(list.index);
            var cam = element.objectReferenceValue as Camera;
            if (Event.current.clickCount == 2)
            {
                Selection.activeObject = cam;
            }

            EditorGUIUtility.PingObject(cam);
        }

        readonly GUIContent m_NameContent = new GUIContent();

        void DrawElementCallback(Rect rect, int index, bool isActive, bool isFocused)
        {
            Camera cam = null;
            if (!GetCameraAtIndex(index, ref cam))
            {
                m_Camera
                    .GetComponent<UniversalAdditionalCameraData>()
                    .UpdateCameraStack();

                // Need to clean out the errorCamera list here.
                errorCameras.Clear();

                return;
            }

            rect.height = EditorGUIUtility.singleLineHeight;
            rect.y += 1;

            var labelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth -= 20f;

            bool warning = false;
            var type = cam.gameObject.GetComponent<UniversalAdditionalCameraData>().renderType;
            if (!s_ValidCameraTypes.Contains(type))
            {
                if (!errorCameras.Contains(cam))
                {
                    errorCameras.Add(cam);
                }

                m_NameContent.text = cam.name;
                EditorGUI.LabelField(rect, m_NameContent, Styles.typeNotSupportedMessage[type], Styles.errorStyle);
                warning = true;
            }
            else if (errorCameras.Contains(cam))
            {
                errorCameras.Remove(cam);
            }

            if (!warning)
            {
                EditorGUI.LabelField(rect, cam.name, type.ToString());

                // Printing if Post Processing is on or not.
                var isPostActive = cam.gameObject.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing;
                if (isPostActive)
                {
                    Rect selectRect = new Rect(rect.width - 20, rect.y, 50, EditorGUIUtility.singleLineHeight);
                    EditorGUI.LabelField(selectRect, "PP");
                }
            }

            EditorGUIUtility.labelWidth = labelWidth;
        }

        /// <summary>
        /// Renders the list of camera stacks and the possible errors that might be found
        /// </summary>
        public UniversalRenderPipelineCameraStackUI(Camera camera, SerializedObject serializedObject, SerializedProperty elements)
        {
            m_Camera = camera;
            m_SerializedObject = serializedObject;
            m_SerializedPropertyElements = elements;

            m_LayerList = new ReorderableList(serializedObject, elements, true, false, true, true);
            m_LayerList.drawElementCallback += DrawElementCallback;
            m_LayerList.onSelectCallback += SelectElement;
            m_LayerList.onRemoveCallback = RemoveCameraFromList;
            m_LayerList.onAddDropdownCallback = AddCameraToCameraList;
            m_LayerList.onCanRemoveCallback = CanRemove;
        }

        /// <summary>
        /// Renders the list of camera stacks and the possible errors that might be found
        /// </summary>
        public void OnGUI()
        {
            EditorGUILayout.Space();

            // Obtain the size of the list ( all the items, + the + - buttons ), and expand to the inspector width and draw it
            var rect = GUILayoutUtility.GetRect(1, m_LayerList.GetHeight(), GUILayout.ExpandWidth(true));
            m_LayerList.DoList(EditorGUI.IndentedRect(rect));

            // If there are errors, display them nicely
            if (errorCameras.Any())
            {
                StringBuilder stringBuilder = new StringBuilder();
                stringBuilder.AppendLine("These cameras are not of a valid type:");
                stringBuilder.AppendLine(string.Join("\n", errorCameras.Select(c => $"  - {c.name}")));
                stringBuilder.AppendLine(Styles.validTypes);
                EditorGUILayout.HelpBox(stringBuilder.ToString(), MessageType.Warning);
            }
            EditorGUILayout.Space();
            EditorGUILayout.Space();

            // Apply any changes to the object that might had happened
            m_SerializedObject.ApplyModifiedProperties();
        }
    }
}
