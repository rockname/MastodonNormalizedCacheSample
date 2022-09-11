# MastodonNormalizedCacheSample
This is a mastodon sample SwiftUI app.<br/>
This app is implemented with the architecture of state management with normalized cache.

| Home | Detail | Profile |
| -- | -- | -- |
| ![](https://user-images.githubusercontent.com/8536870/189512478-557a8d30-45f9-41f0-9d3a-2988929a55f0.png) | ![](https://user-images.githubusercontent.com/8536870/189512480-57dc1acf-caac-476b-8e4d-ef0b0100683d.png) | ![](https://user-images.githubusercontent.com/8536870/189512477-c78bc70a-62fc-4b8f-971f-78af2a8428ee.png) |

## Motivation

For example, let's say you are developing an iOS application for **mastodon**.<br/>
If you develop an iOS app for mastodon, for example, you need to make sure that no matter which screen you use to perform a favorite action on a post, the same post on all screens should reflect the same state.
The same is true for other mutations, such as updating profile information.

To prevent data inconsistencies, a good solution is to hoist up the states that require synchronization as Global State and propagate them to each screen, rather than managing them separately on each screen.

The Single Store architecture such as Redux is well known as a method of managing Global State, but it is an overkill architecture when most of the state to be managed is Server State, such as responses from the server.

## Solution

In order to meet these requirements, the architecture of state management with **Normalized Cache** is adopted.<br/>
A GraphQL Client library such as [Apollo Client](https://www.apollographql.com/apollo-client) and [Relay](https://relay.dev/) provides this functionality.

Normalized Cache is that splitting the data retrieved from the server into individual objects, assign a logically unique identifier to each object, and store them in a flat data structure.

This allows, for example, in the case of the mastodon application shown in the previous example, favorite actions on a post object will be properly updated by a single uniquely managed post object, so that they can be reflected in the UI of each screen without inconsistencies.
