// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/jballerina.java;
import ballerina/io;

@test:BeforeSuite
function setupServer() returns error? {
    check startSecureServer();
}

@test:Config {dependsOn: [testListenerEcho], enable: false}
function testProtocolVersion() returns @tainted error? {
    io:println("-------------------------------------testProtocolVersion---------------------");
    Error|Client socketClient = new ("localhost", 9002, secureSocket = {
        cert: certPath,
        protocol: {
            name: TLS,
            versions: ["TLSv1.1"] // server only support TLSv1.2 but client only support TLSv1.1 write should fail
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
    });

    if (socketClient is Client) {
        test:assertFail(msg = "Server only support TLSv1.2 initialization should fail.");
        check socketClient->close();
    }
    io:println("SecureClient: ", socketClient);
}

@test:Config {dependsOn: [testProtocolVersion], enable: false}
function testCiphers() returns @tainted error? {
     io:println("-------------------------------------testCiphers---------------------");
    Error|Client socketClient = new ("localhost", 9002, secureSocket = {
        cert: certPath,
        protocol: {
            name: TLS,
            versions: ["TLSv1.2", "TLSv1.1"]
        },
        ciphers: ["TLS_RSA_WITH_AES_128_CBC_SHA"] // server only support TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA write should fail
    });

    if (socketClient is Client) {
        test:assertFail(msg = "Server only support TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA cipher initialization should fail.");
        check socketClient->close();
    }
    io:println("SecureClient: ", socketClient);
}

@test:Config {dependsOn: [testCiphers], enable: false}
function testSecureClientEcho() returns @tainted error? {
    io:println("-------------------------------------testSecureClientEcho---------------------");
    Client socketClient = check new ("localhost", 9002, secureSocket = {
        cert: certPath,
        protocol: {
            name: TLS,
            versions: ["TLSv1.2", "TLSv1.1"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
    });

    string msg = "Hello Ballerina Echo from secure client";
    byte[] msgByteArray = msg.toBytes();
    check socketClient->writeBytes(msgByteArray);

   readonly & byte[] receivedData = check socketClient->readBytes();
   test:assertEquals('string:fromBytes(receivedData), msg, "Found unexpected output");

    check socketClient->close();
}

@test:Config {dependsOn: [testSecureClientEcho], enable: false}
function testSecureClientWithTruststore() returns @tainted error? {
    io:println("-------------------------------------testSecureClientWithTruststore---------------------");
    Client socketClient = check new ("localhost", PORT7, secureSocket = {
        cert: {
            path: truststore,
            password:"ballerina"
        },
        protocol: {
            name: TLS,
            versions: ["TLSv1.2", "TLSv1.1"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"],
        sessionTimeout: 600,
        handshakeTimeout: 10
    });

    string msg = "Hello Ballerina Echo from secure client";
    byte[] msgByteArray = msg.toBytes();
    check socketClient->writeBytes(msgByteArray);

   readonly & byte[] receivedData = check socketClient->readBytes();
   test:assertEquals('string:fromBytes(receivedData), msg, "Found unexpected output");

    check socketClient->close();
}

@test:Config {dependsOn: [testSecureClientEcho], enable: false}
function testSecureSocketConfigEnableFalse() returns @tainted error? {
    io:println("-------------------------------------testSecureSocketConfigEnableFalse---------------------");
    Client socketClient = check new ("localhost", PORT1, secureSocket = {
        enable: false,
        cert: {
            path: truststore,
            password:"ballerina"
        },
        protocol: {
            name: TLS,
            versions: ["TLSv1.2", "TLSv1.1"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
    });

    string msg = "Hello ballerina from client";
    byte[] msgByteArray = msg.toBytes();
    check socketClient->writeBytes(msgByteArray);

   readonly & byte[] receivedData = check socketClient->readBytes();
   test:assertEquals('string:fromBytes(receivedData), msg, "Found unexpected output");

   check socketClient->close();
}

@test:Config {dependsOn: [testSecureSocketConfigEnableFalse], enable: false}
isolated function testSecureClientWithInvalidCertPath() returns @tainted error? {
    io:println("-------------------------------------testSecureClientWithInvalidCertPath---------------------");
    Error|Client socketClient = new ("localhost", 9002, secureSocket = {
        cert: {
            path: "invalid",
            password:"ballerina"
        },
        protocol: {
            name: TLS,
            versions: ["TLSv1.2", "TLSv1.1"]
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
    });
    
    if (socketClient is Client) {
        test:assertFail(msg = "Invalid trustore path provided initialization should fail.");
    } else {
        io:println(socketClient.message());
    }
}

@test:Config {enable: false}
isolated function testSecureClientWithEmtyTrustStore() returns @tainted error? {
    io:println("-------------------------------------testSecureClientWithEmtyTrustStore---------------------");
    Error|Client socketClient = new ("localhost", 9002, secureSocket = {
        cert: {
            path: "",
            password: "ballerina"
        }
    });

    if (socketClient is Client) {
        test:assertFail(msg = "Empty trustore path provided, initialization should fail.");
    } else {
        test:assertEquals(socketClient.message(), "TrustStore file location must be provided for secure connection");
    }
}

@test:Config {enable: false}
function testSecureClientWithEmtyTrustStorePassword() returns @tainted error? {
    io:println("-------------------------------------testSecureClientWithEmtyTrustStorePassword---------------------");
    Error|Client socketClient = new ("localhost", 9002, secureSocket = {
        cert: {
            path: truststore,
            password:""
        }
    });

    if (socketClient is Client) {
        test:assertFail(msg = "Empty trustore password provided, initialization should fail.");
    } else {
        test:assertEquals(socketClient.message(), "TrustStore password must be provided for secure connection");
    }
}

@test:Config {enable: false}
function testSecureClientWithEmtyCert() returns @tainted error? {
    io:println("-------------------------------------testSecureClientWithEmtyCert---------------------");
    Error|Client socketClient = new ("localhost", 9002, secureSocket = {
        cert: ""
    });

    if (socketClient is Client) {
        test:assertFail(msg = "Empty trustore password provided, initialization should fail.");
    } else {
        test:assertEquals(socketClient.message(), "Certificate file location must be provided for secure connection");
    }
}

@test:Config {enable: false}
function testBasicSecureClient() returns error? {
    io:println("-------------------------------------testBasicSecureClient---------------------");
    Client socketClient = check new ("localhost", 9002, secureSocket = {
        cert: certPath
    });

    string msg = "Hello Ballerina basic secure client";
    byte[] msgByteArray = msg.toBytes();
    check socketClient->writeBytes(msgByteArray);

   readonly & byte[] receivedData = check socketClient->readBytes();
   test:assertEquals('string:fromBytes(receivedData), msg, "Found unexpected output");

    check socketClient->close();
}

@test:AfterSuite {}
function stopServer() returns error? {
    check stopSecureServer();
}

public function startSecureServer() returns error? = @java:Method {
    name: "startSecureServer",
    'class: "io.ballerina.stdlib.tcp.testutils.TestUtils"
} external;

public function stopSecureServer() returns error? = @java:Method {
    name: "stopSecureServer",
    'class: "io.ballerina.stdlib.tcp.testutils.TestUtils"
} external;
