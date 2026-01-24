<%--@import boutique.model.BaseLayout--%>
@import gg.jte.Content

<%--@param BaseLayout baseLayout--%>
@param Content centralViewPort
<%--@param Content footer = null--%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Welcome!</title>
<%--    <link type="text/css" rel="stylesheet" href="${baseLayout.getServerPath()}/css/materialize.min.css"--%>
<%--          media="screen,projection"/>--%>
<%--    <link type="text/css" rel="stylesheet" href="${baseLayout.getServerPath()}/css/icons.css"--%>
<%--          media="screen,projection"/>--%>
<%--    <link type="text/css" rel="stylesheet" href="${baseLayout.getServerPath()}/css/main.css"--%>
<%--          media="screen,projection"/>--%>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta charset="UTF-8"/>
</head>

<body class="has-fixed-sidenav">
<header>

    <!-- head bar -->
    <div class="navbar-fixed">
        <nav class="nav navbar">
            <div class="nav-wrapper primary">
                <a href="#" data-target="nav-mobile" class="sidenav-trigger">sidenav</a>
                <a class="btn filled icon-right waves-effect waves-light"
                   href="#">
                    nothing
                </a>
                    <div class="input-field inline" style="background-color: #006495; width: 20%;">
                        <input id="email" type="email" placeholder=" ">
                        <label for="email" style="color: aliceblue;">still nothing</label>
                    </div>
            </div>
        </nav>
    </div>

    <!-- left bar -->
    <ul id="nav-mobile" class="sidenav sidenav-fixed">
        <li class="no-padding">
            <ul class="collapsible expandable">
                <li>left bar</li>
            </ul>

            <ul class="collapsible expandable">
                <li class="bold waves-effect">
                    <a class="collapsible-header waves-effect">Stat not<i
                                class="material-icons chevron">chevron_right</i></a>

                    <div class="collapsible-body">
                        <ul class="collapsible expandable" style="padding-bottom: 80px;">
                                <li class="bold waves-effect">
                                    <a class="collapsible-header waves-effect active">up nav<i
                                                class="material-icons chevron">chevron_right</i></a>
                                    <div class="collapsible-body">
                                        <ul>
                                            <li>sub nav</li>
                                        </ul>
                                    </div>
                                </li>
                        </ul>
                    </div>
                </li>
            </ul>
        </li>
    </ul>
</header>

<main>
    ${centralViewPort}
</main>

<footer class="page-footer">
    <div class="container">
        <div class="row">
            <div class="col s6 m3">
                <ul>
                    <li><a href="#!">Stand with Ukraine</a></li>
                </ul>
            </div>
<%--            <div class="col s6 m3">V. ${baseLayout.getApplicationVersion()}</div>--%>
        </div>
    </div>
</footer>

<%--<script type="text/javascript" src="${baseLayout.getServerPath()}/js/materialize.min.js"></script>--%>
<%--<script type="text/javascript" src="${baseLayout.getServerPath()}/js/main.js"></script>--%>
<%--<script type="text/javascript" src="${baseLayout.getServerPath()}/js/img_res.js"></script>--%>
</body>

</html>