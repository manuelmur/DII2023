//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract subasta {

    address payable benef; //beneficiario de la puja, recibira el dinero
    uint tiempoFinalizacion; //tiempo en segundos que estara la puja abierta

    address public pujadorActual;
    uint public precioActual;
    address gestor;

    mapping(address => uint) devoluciones; //creamos un mapa para guardar la dirección y la puja

    bool finalizada;

    event pujaAumentada(address pujador, uint cantidad);
    event FinalPuja(address comprador, uint cantidad);

    error PujaFinalizada();
    error PujaMasAlto(uint precioActual);
    error SubastaSinTerminar(uint tiempoRest);

    //Al desplegar el contrato se debera de indicar la duracion y el beneficiario
    constructor(uint duracionSubasta, uint precioSalida, address payable direccionBenef) {
        benef = direccionBenef;
        tiempoFinalizacion = block.timestamp + duracionSubasta;
        gestor = msg.sender;
        precioActual = precioSalida;
    }

    modifier requiereGestor() {
        require(gestor == msg.sender, "No eres el gestor");
        _;
    }

    //Funcion para consultar cuanto tiempo le queda a la subasta
    function tiempoRestante() public view returns(uint) {
        return uint(tiempoFinalizacion - block.timestamp);
    }

    //Funcion que permite pujar si la puja siga activa y si la cantidad es mayor a la puja actual
    function pujar() external payable {

        if (block.timestamp > tiempoFinalizacion)
            revert PujaFinalizada();

        if (msg.value <= precioActual)
            revert PujaMasAlto(precioActual);

        if (precioActual != 0) {
            devoluciones[pujadorActual] += precioActual;
        }
        pujadorActual = msg.sender;
        precioActual = msg.value;
        emit pujaAumentada(msg.sender, msg.value);
    }

    //Funcion que permite retirar el dinero pujado si ya hay una puja mayor
    function sacarPuja() external returns (bool) {
        uint cantidad = devoluciones[msg.sender];
        if (cantidad > 0) {
            devoluciones[msg.sender] = 0;

            if (!payable(msg.sender).send(cantidad)) {
                devoluciones[msg.sender] = cantidad;
                return false;
            }
        }
        return true;
    }

    //Funcion que transfiere el dinero al beneficiario cuando ha terminado la puja
    function Transferir() external requiereGestor {

        if (block.timestamp < tiempoFinalizacion)
            revert SubastaSinTerminar(tiempoFinalizacion - block.timestamp);
        if (finalizada)
            revert PujaFinalizada();

        finalizada = true;
        emit FinalPuja(pujadorActual, precioActual);

        benef.transfer(precioActual);
    }
}

/*
Referencias de código:
https://blog.finxter.com/solidity-by-example-part-12-simple-open-auction/
https://www.bitdegree.org/learn/best-code-editor/solidity-simple-auction-example
https://medium.com/@bryn.bellomy/solidity-tutorial-building-a-simple-auction-contract-fcc918b0878a
https://www.tutorialspoint.com/solidity/solidity_events.htm
*/
