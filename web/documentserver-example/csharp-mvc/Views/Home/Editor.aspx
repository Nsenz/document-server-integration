﻿<%@ Page Title="ONLYOFFICE" Language="C#" Inherits="System.Web.Mvc.ViewPage<OnlineEditorsExampleMVC.Models.FileModel>" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.Configuration" %>
<%@ Import Namespace="OnlineEditorsExampleMVC.Helpers" %>

<!DOCTYPE html>

<html>
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, minimal-ui" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="mobile-web-app-capable" content="yes" />
    <!--
    *
    * (c) Copyright Ascensio System SIA 2021
    *
    * Licensed under the Apache License, Version 2.0 (the "License");
    * you may not use this file except in compliance with the License.
    * You may obtain a copy of the License at
    *
    *     http://www.apache.org/licenses/LICENSE-2.0
    *
    * Unless required by applicable law or agreed to in writing, software
    * distributed under the License is distributed on an "AS IS" BASIS,
    * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    * See the License for the specific language governing permissions and
    * limitations under the License.
    *
    -->
    <link rel="icon" href="<%= "content/images/" + Model.DocumentType + ".ico" %>" type="image/x-icon" />
    <title><%= Model.FileName + " - ONLYOFFICE" %></title>
    
    <%: Styles.Render("~/Content/editor") %>

</head>
<body>
    <div class="form">
        <div id="iframeEditor">
        </div>
    </div>
    
    <%: Scripts.Render(new []{ WebConfigurationManager.AppSettings["files.docservice.url.site"] + WebConfigurationManager.AppSettings["files.docservice.url.api"] }) %>

    <script type="text/javascript" language="javascript">

        var docEditor;

        var innerAlert = function (message) {
            if (console && console.log)
                console.log(message);
        };

        // the application is loaded into the browser
        var onAppReady = function () {
            innerAlert("Document editor ready");
        };

        // the document is modified
        var onDocumentStateChange = function (event) {
            var title = document.title.replace(/\*$/g, "");
            document.title = title + (event.data ? "*" : "");
        };

        // the user is trying to switch the document from the viewing into the editing mode
        var onRequestEditRights = function () {
            location.href = location.href.replace(RegExp("editorsMode=view\&?", "i"), "");
        };

        // an error or some other specific event occurs
        var onError = function (event) {
            if (event)
                innerAlert(event.data);
        };

        // the document is opened for editing with the old document.key value
        var onOutdatedVersion = function (event) {
            location.reload(true);
        };

        // replace the link to the document which contains a bookmark
        var replaceActionLink = function(href, linkParam) {
            var link;
            var actionIndex = href.indexOf("&actionLink=");
            if (actionIndex != -1) {
                var endIndex = href.indexOf("&", actionIndex + "&actionLink=".length);
                if (endIndex != -1) {
                    link = href.substring(0, actionIndex) + href.substring(endIndex) + "&actionLink=" + encodeURIComponent(linkParam);
                } else {
                    link = href.substring(0, actionIndex) + "&actionLink=" + encodeURIComponent(linkParam);
                }
            } else {
                link = href + "&actionLink=" + encodeURIComponent(linkParam);
            }
            return link;
        }

        // the user is trying to get link for opening the document which contains a bookmark, scrolling to the bookmark position
        var onMakeActionLink = function (event) {
            var actionData = event.data;
            var linkParam = JSON.stringify(actionData);
            docEditor.setActionLink(replaceActionLink(location.href, linkParam));  // set the link to the document which contains a bookmark
        };

        // the meta information of the document is changed via the meta command
        var onMetaChange = function (event) {
            var favorite = !!event.data.favorite;
            var title = document.title.replace(/^\☆/g, "");
            document.title = (favorite ? "☆" : "") + title;
            docEditor.setFavorite(favorite);  // change the Favorite icon state
        };

        // the user is trying to insert an image by clicking the Image from Storage button
        var onRequestInsertImage = function (event) {
            <% string logoUrl;%>
            <% Model.GetLogoConfig(out logoUrl); %>
            docEditor.insertImage({  // insert an image into the file
                "c": event.data.c,
                <%= logoUrl%>
            })
        };

        // the user is trying to select document for comparing by clicking the Document from Storage button
        var onRequestCompareFile = function () {
            <% string compareFileData; %>
            <% Model.GetCompareFileData(out compareFileData); %>
            docEditor.setRevisedFile(<%=compareFileData%>);  // select a document for comparing
        };

        // the user is trying to select recipients data by clicking the Mail merge button
        var onRequestMailMergeRecipients = function (event) {
            <% string dataMailMergeRecipients; %>
            <% Model.GetMailMergeConfig(out dataMailMergeRecipients); %>
            docEditor.setMailMergeRecipients(<%= dataMailMergeRecipients%>);  // insert recipient data for mail merge into the file
        };

        var config = <%= Model.GetDocConfig(Request, Url) %>;

        config.width = "100%";
        config.height = "100%";

        config.events = {
            'onAppReady': onAppReady,
            'onDocumentStateChange': onDocumentStateChange,
            'onRequestEditRights': onRequestEditRights,
            'onError': onError,
            'onOutdatedVersion': onOutdatedVersion,
            "onMakeActionLink": onMakeActionLink,
            "onMetaChange": onMetaChange,
            "onRequestInsertImage": onRequestInsertImage,
            "onRequestCompareFile": onRequestCompareFile,
            "onRequestMailMergeRecipients": onRequestMailMergeRecipients,
        };

        <% string hist, histData; %>
        <% Model.GetHistory(out hist, out histData); %>
        <% if (!string.IsNullOrEmpty(hist) && !string.IsNullOrEmpty(histData))
        { %>
        // the user is trying to show the document version history
        config.events['onRequestHistory'] = function () {
            docEditor.refreshHistory(<%= hist %>);  // show the document version history
        };
        // the user is trying to click the specific document version in the document version history
        config.events['onRequestHistoryData'] = function (event) {
            var ver = event.data;
            var histData = <%= histData %>;
            docEditor.setHistoryData(histData[ver - 1]);  // send the link to the document for viewing the version history
        };
        // the user is trying to go back to the document from viewing the document version history
        config.events['onRequestHistoryClose '] = function () {
            document.location.reload();
        };
        <% } %>

        var сonnectEditor = function () {
            docEditor = new DocsAPI.DocEditor("iframeEditor", config);
        };

        if (window.addEventListener) {
            window.addEventListener("load", сonnectEditor);
        } else if (window.attachEvent) {
            window.attachEvent("load", сonnectEditor);
        }

    </script>
</body>
</html>
