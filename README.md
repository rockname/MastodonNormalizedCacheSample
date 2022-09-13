# MastodonNormalizedCacheSample
This is a mastodon sample SwiftUI app.<br/>
This app is implemented with the architecture of state management with normalized cache.

| Home | Detail | Profile |
| -- | -- | -- |
| ![](https://user-images.githubusercontent.com/8536870/189512478-557a8d30-45f9-41f0-9d3a-2988929a55f0.png) | ![](https://user-images.githubusercontent.com/8536870/189512480-57dc1acf-caac-476b-8e4d-ef0b0100683d.png) | ![](https://user-images.githubusercontent.com/8536870/189512477-c78bc70a-62fc-4b8f-971f-78af2a8428ee.png) |

## Requirements
Xcode 14 beta 1+ <br/>
iOS 16.0+

## Motivation

If you develop an iOS app for mastodon, for example, you need to make sure that no matter which screen you use to perform a favorite action on a post, the same post on all screens should reflect the same state.
The same is true for other mutations, such as updating profile information.

To prevent data inconsistencies, a good solution is to hoist up the states that require synchronization as Global State and propagate them to each screen, rather than managing them separately on each screen.

![](https://user-images.githubusercontent.com/8536870/189909897-220a3cf7-ef90-4bd6-a55d-6eaadd80cd6c.png)

The Single Store architecture such as [Redux](https://redux.js.org/) is well known as a method of managing Global State.

![](https://user-images.githubusercontent.com/8536870/189910601-de3f0d60-6319-4c8b-9382-f1ad2e3676c1.png)

But it is an overkill architecture when most of the state to be managed is Server State, such as responses from the server.

![](https://user-images.githubusercontent.com/8536870/189915150-a7b1c3e5-f9af-4cb8-a28a-fe3a977b1708.png)

## Solution

In order to meet these requirements, the architecture of state management with **Normalized Cache** is adopted.<br/>
A GraphQL Client library such as [Apollo Client](https://www.apollographql.com/apollo-client) and [Relay](https://relay.dev/) provides this functionality.

![](https://user-images.githubusercontent.com/8536870/189913270-f348277f-0140-4c33-82e2-49f2eab754f9.png)

Normalized Cache is that splitting the data retrieved from the server into individual objects, assign a logically unique identifier to each object, and store them in a flat data structure.

![](https://user-images.githubusercontent.com/8536870/189914659-996d4534-4d8f-414e-83a2-5b64e946a6e3.png)

This allows, for example, in the case of the mastodon application shown in the previous example, favorite actions on a post object will be properly updated by a single uniquely managed post object, so that they can be reflected in the UI of each screen without inconsistencies.

## Detail

TBD
