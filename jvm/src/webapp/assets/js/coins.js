function CoinCtrl($scope) {
    $scope.coins = {};

    var socket = new SockJS('/sockjs');
    var stompClient = Stomp.over(socket);
    stompClient.connect('', '', function(frame) {
        console.log('Connected ' + frame);

        stompClient.subscribe("/topic/recog/coin.*", function(message) {
            $scope.$apply(function() {
                $scope.coins = JSON.parse(message.body);
            });
        });


    }, function(error) {
        console.log("STOMP protocol error " + error);
    });

}
