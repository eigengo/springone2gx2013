angular.module('coins', []).
    directive('display', function() {
        return {
            scope: { display: '@' },
            restrict: 'A',
            link: function($scope, element, attrs) {
                var scale = 1.0;
                var offset = {x: 0, y: 0};
                var coinColor = 'green';

                if (attrs.fill) coinColor = attrs.fill;
                if (attrs.scale) scale = attrs.scale;
                if (attrs.dx) offset.x = parseInt(attrs.dx);
                if (attrs.dy) offset.y = parseInt(attrs.dy);

                var drawCoin = function(context, center, radius) {
                    context.beginPath();
                    context.arc(center.x, center.y, radius, 0, 2 * Math.PI, false);
                    context.fillStyle = coinColor;
                    context.fill();
                    context.lineWidth = 2;
                    context.strokeStyle = '#003300';
                    context.stroke();
                };

                attrs.$observe('display', function(rawValue) {
                    var value = JSON.parse(rawValue);
                    if (!value.coins) return;

                    var canvas = element[0];
                    var context = canvas.getContext('2d');

                    // clear
                    context.clearRect(0, 0, canvas.width, canvas.height);

                    // draw coins
                    for (var i = 0; i < value.coins.length; i++) {
                        var coin = value.coins[i];
                        coin.center.x *= scale;
                        coin.center.y *= scale;
                        coin.center.x += offset.x;
                        coin.center.y += offset.y;
                        coin.radius *= scale;

                        drawCoin(context, coin.center, coin.radius);
                    }

                });
            }
        };
    }).
    directive('tabs', function() {
        return {
            restrict: 'E',
            transclude: true,
            scope: {},
            controller: function($scope, $element) {
                var panes = $scope.panes = [];

                $scope.select = function(pane) {
                    angular.forEach(panes, function(pane) {
                        pane.selected = false;
                    });
                    pane.selected = true;
                };

                this.addPane = function(pane) {
                    if (panes.length == 0) $scope.select(pane);
                    panes.push(pane);
                };
            },
            template:
                '<div class="tabbable">' +
                    '<ul class="nav nav-tabs">' +
                    '<li ng-repeat="pane in panes" ng-class="{active:pane.selected}">'+
                    '<a href="" ng-click="select(pane)">{{pane.title}}</a>' +
                    '</li>' +
                    '</ul>' +
                    '<div class="tab-content" ng-transclude></div>' +
                    '</div>',
            replace: true
        };
    }).
    directive('pane', function() {
        return {
            require: '^tabs',
            restrict: 'E',
            transclude: true,
            scope: { title: '@' },
            link: function(scope, element, attrs, tabsCtrl) {
                tabsCtrl.addPane(scope);
            },
            template: '<div class="tab-pane" ng-class="{active: selected}" ng-transclude></div>',
            replace: true
        };
    })