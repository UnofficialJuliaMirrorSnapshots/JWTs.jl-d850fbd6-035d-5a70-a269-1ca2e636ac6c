using JWTs
using Test
using JSON

function print_header(msg)
    println("")
    println("-"^60)
    println(msg)
    println("-"^60)
end

function test_and_get_keyset(url)
    print_header("keyset: $url")

    keyset = JWKSet(url)
    @test length(keyset.keys) == 0

    refresh!(keyset)
    @test length(keyset.keys) > 0
    for (k,v) in keyset.keys
        println("    ", k, " => ", v.key)
    end

    keyset
end

function test_signing(keyset_url)
    keyset = test_and_get_keyset(keyset_url)

    data = [
        JSON.parse("""{
            "jti": "0b821616-0a5f-47f3-af00-8caf03619303",
            "exp": 1543351759,
            "nbf": 0,
            "iat": 1543315759,
            "iss": "https://example.com/auth/",
            "aud": "portal",
            "sub": "b1df5448-a16b-4a13-b03b-2213d56ea1b5",
            "typ": "Bearer",
            "azp": "portal",
            "auth_time": 1543315759,
            "session_state": "f196425d-226b-4e6d-bc81-feecb276f424",
            "acr": "1",
            "allowed-origins": [ "" ],
            "realm_access": { "roles": [ "uma_authorization" ] },
            "resource_access": {
                "broker": { "roles": [ "read-token" ] },
                "account": { "roles": [ "manage-account", "manage-account-links", "view-profile" ] }
            },
            "preferred_username": "chhhhhhhhhhhhhhhhhhhhhhhhhaaaaaaaaaaaaabbb"
        }"""),
        JSON.parse("""{
            "iss": "https://auth2.juliacomputing.io/dex",
            "sub": "ChUxjfgsajfurjsjdut0483672kdhgstgy283jssZQ",
            "aud": "example-audience",
            "exp": 1536080651,
            "iat": 1535994251,
            "nonce": "1777777777777aaaaaaaaabbbbbbbbbb",
            "at_hash": "222222-G-JJJJJJJJJJJJJ",
            "email": "user@example.com",
            "email_verified": true,
            "name": "Example User"
        }""")
    ]

    print_header("signing")
    for k in keys(keyset.keys)
        for d in data
            jwt = JWT(; payload=d)
            @test !issigned(jwt)
            sign!(jwt, keyset, k)
            @test issigned(jwt)
            @test isvalid(jwt)
            @test isverified(jwt)

            println("    JWT: ", jwt)
            jwt2 = JWT(; jwt=string(jwt))
            @test issigned(jwt2)
            @test !isverified(jwt2)
            @test isvalid(jwt2) === nothing
            @test validate!(jwt, keyset, k)
            @test issigned(jwt)
            @test isvalid(jwt)
            @test isverified(jwt)

            jwt2 = JWT(; jwt=string(jwt))
            @test issigned(jwt2)
            @test !isverified(jwt2)
            @test isvalid(jwt2) === nothing
            invalidkey = first(filter(x->x!=k, keys(keyset.keys)))
            @test !validate!(jwt2, keyset, invalidkey)
            @test issigned(jwt2)
            @test !isvalid(jwt2)
            @test isverified(jwt2)
        end
    end
end

test_and_get_keyset("https://www.googleapis.com/oauth2/v3/certs")
test_signing("file://" * joinpath(@__DIR__, "jwkkey.json"))
