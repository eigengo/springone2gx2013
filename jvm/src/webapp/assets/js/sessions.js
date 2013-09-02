function SessionsCtrl($scope) {
    // initialization
    $scope.sessions = [];

    // Connect to the server on path /sockjs and then create the STOMP protocol lient
    var socket = new SockJS('/sockjs');
    var stompClient = Stomp.over(socket);
    stompClient.connect('', '',
        function(frame) {
            // receive notifications on the recog/sessions topic
            stompClient.subscribe("/topic/recog/sessions", function(message) {
                $scope.$apply(function() {
                    $scope.sessions = angular.fromJson(message.body);
                });
            });
        },
        function(error) {
            console.log("STOMP protocol error " + error);
        }
    );

}

