using UnityEngine;

/// <summary>
/// First greybox city prototype for TIGER CITY 3D.
/// Add this component to an empty GameObject in a Unity scene.
/// All geometry is generated from built-in primitives so no external assets are required.
/// </summary>
public sealed class CityPrototype : MonoBehaviour
{
    [Header("City layout")]
    [Min(4)] public int blocksPerSide = 6;
    [Min(8f)] public float blockSize = 18f;
    [Min(2f)] public float roadWidth = 6f;

    [Header("Building variation")]
    [Min(3f)] public float minBuildingHeight = 5f;
    [Min(3f)] public float maxBuildingHeight = 24f;

    private void Start()
    {
        BuildCity();
    }

    [ContextMenu("Build City")]
    public void BuildCity()
    {
        ClearGeneratedCity();

        float citySize = blocksPerSide * blockSize + (blocksPerSide + 1) * roadWidth;
        CreatePrimitive("Ground", PrimitiveType.Plane,
            new Vector3(citySize / 2f, -0.12f, citySize / 2f),
            new Vector3(citySize / 10f, 1f, citySize / 10f),
            new Color(0.24f, 0.34f, 0.22f));

        for (int i = 0; i <= blocksPerSide; i++)
        {
            float p = i * (blockSize + roadWidth);
            CreatePrimitive("Road X " + i, PrimitiveType.Cube,
                new Vector3(citySize / 2f, 0f, p + roadWidth / 2f),
                new Vector3(citySize, 0.12f, roadWidth),
                new Color(0.12f, 0.13f, 0.14f));
            CreatePrimitive("Road Z " + i, PrimitiveType.Cube,
                new Vector3(p + roadWidth / 2f, 0f, citySize / 2f),
                new Vector3(roadWidth, 0.12f, citySize),
                new Color(0.12f, 0.13f, 0.14f));
        }

        Random.InitState(303);
        for (int x = 0; x < blocksPerSide; x++)
        {
            for (int z = 0; z < blocksPerSide; z++)
            {
                float startX = roadWidth + x * (blockSize + roadWidth);
                float startZ = roadWidth + z * (blockSize + roadWidth);
                float height = Random.Range(minBuildingHeight, maxBuildingHeight);
                float width = Random.Range(7f, 12f);
                float depth = Random.Range(7f, 12f);
                Vector3 position = new Vector3(
                    startX + blockSize / 2f,
                    height / 2f,
                    startZ + blockSize / 2f);

                Color facade = Color.Lerp(
                    new Color(0.42f, 0.46f, 0.50f),
                    new Color(0.72f, 0.68f, 0.58f),
                    Random.value);

                CreatePrimitive("Building " + x + "-" + z, PrimitiveType.Cube,
                    position, new Vector3(width, height, depth), facade);
            }
        }

        SetupLightingAndCamera(citySize);
    }

    private GameObject CreatePrimitive(string objectName, PrimitiveType type,
        Vector3 position, Vector3 scale, Color color)
    {
        GameObject item = GameObject.CreatePrimitive(type);
        item.name = objectName;
        item.transform.SetParent(transform, false);
        item.transform.localPosition = position;
        item.transform.localScale = scale;

        Renderer renderer = item.GetComponent<Renderer>();
        if (renderer != null)
        {
            Material material = new Material(Shader.Find("Standard"));
            material.color = color;
            renderer.material = material;
        }
        return item;
    }

    private void SetupLightingAndCamera(float citySize)
    {
        Light sun = FindObjectOfType<Light>();
        if (sun == null)
        {
            GameObject lightObject = new GameObject("City Sun");
            sun = lightObject.AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.intensity = 1.1f;
            lightObject.transform.rotation = Quaternion.Euler(50f, -35f, 0f);
        }

        Camera camera = Camera.main;
        if (camera == null)
        {
            GameObject cameraObject = new GameObject("Main Camera");
            cameraObject.tag = "MainCamera";
            camera = cameraObject.AddComponent<Camera>();
        }

        camera.transform.position = new Vector3(citySize * 0.85f, citySize * 0.8f, -citySize * 0.85f);
        camera.transform.LookAt(new Vector3(citySize / 2f, 0f, citySize / 2f));
        camera.fieldOfView = 45f;
        camera.nearClipPlane = 0.1f;

        CityOrbitCamera orbit = camera.GetComponent<CityOrbitCamera>();
        if (orbit == null) orbit = camera.gameObject.AddComponent<CityOrbitCamera>();
        GameObject focus = new GameObject("City Camera Focus");
        focus.transform.position = new Vector3(citySize / 2f, 0f, citySize / 2f);
        orbit.target = focus.transform;
        orbit.distance = citySize * 1.15f;
    }

    private void ClearGeneratedCity()
    {
        for (int i = transform.childCount - 1; i >= 0; i--)
        {
            GameObject child = transform.GetChild(i).gameObject;
            if (Application.isPlaying) Destroy(child);
            else DestroyImmediate(child);
        }
    }
}
