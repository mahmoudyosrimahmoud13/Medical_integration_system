"""Image links follow the address people use, also through a Cloudflare tunnel or a proxy."""


async def _img(client, headers=None):
    r = await client.post("/Auth/Login", json={"userName": "patient@healthhub.local", "password": "Patient@12345"}, headers=headers or {})
    return r.json()["imgSrc"]


async def test_direct_request_uses_its_own_address(client):
    assert (await _img(client)).startswith("http://test/Image/")


async def test_tunnel_address_is_used_for_image_links(client):
    url = await _img(client, {"x-forwarded-proto": "https", "host": "blue-sky.trycloudflare.com"})
    assert url.startswith("https://blue-sky.trycloudflare.com/Image/")
    url = await _img(client, {"x-forwarded-proto": "https,http", "x-forwarded-host": "app.example.com"})
    assert url.startswith("https://app.example.com/Image/")
