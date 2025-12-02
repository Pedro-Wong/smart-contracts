// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// TODO: modifier apenas_dono para mudar o preco ou cancelar o contrato (perfil falso?)
interface ERC20Interface {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 contract RedeSocialNotarizada is ERC20Interface{
    
    struct RegistroSocial{
        string perfil;
        uint256 horaCriado;
    }

    mapping(address => RegistroSocial) public registros;

    // array para guardar detentor de token
    address[] public detentores_de_tokens;
    //controlar saldo de token de cada usuario 
    mapping(address => uint) public saldo_tokens;

    mapping(address => mapping(address => uint)) public permite_sacar;


    uint256 public preco;       // preco em wei para salvar nesse contrato
    address public criador;     // criador do contrato
    uint256 count;

    // Evento para ser emitido quando o perfil é guardado
    event Guardado(string _perfil, address _dono);



    modifier apenasCriador {
        require(msg.sender == criador, "Apenas o criador do contrato pode fazer isso!");
        _;
    }



    /**
     * @dev Armazena o preco, criador e cria novos tokens para usar o contrato
     */
    constructor(uint256 _preco) {
        preco = _preco;
        criador = msg.sender;
        count = 10000;
        adicionar_detentor(criador);

    }
    
    function adicionar_detentor(address _detentor) private {
        if (saldo_tokens[_detentor] == 0){
            detentores_de_tokens.push(_detentor);
        }
    }







    /**
     * @dev Permite salvar um nome de perfil associado a um endereco de carteira. Requer que seja enviado o valor definido no construtor do contrato.
     * @param _perfil String representando o nome do perfil a ser salvo.
     * @param _dono Endereco da carteira do dono do perfil.
     */
    function guardar(string calldata _perfil, address _dono) public payable {
        require(registros[_dono].horaCriado == 0, "Um perfil ja esta guardado!");
        require(msg.value >= preco, "Precisa receber o valor correto!");

        envia_troco();
        envia_pagamento();

        registros[_dono].perfil = _perfil;
        registros[_dono].horaCriado = block.timestamp;

        count++;
        
        emit Guardado(_perfil, _dono);

        emitir_token();
    }

    /**
    * @dev Envia troco para o dono do perfil, se necessário. 
    */     
    function envia_troco() private {
        uint256 valor = msg.value - preco;

        if (valor > 0){
            payable(msg.sender).transfer(valor);
        }
    } 
      
    /**
    * @dev Envia o saldo restante do contrato para o criador
    */
    function envia_pagamento() private {
        // envia o resto do saldo do contrato para o criador
        payable(criador).transfer(address(this).balance);
    }

    function emitir_token() private {
        // emitir toekn para msg.sender
    }

    function name() external pure returns (string memory){
        return "Rede Social Notarizada Token";
    }
    function symbol() external pure returns (string memory){
        return "RSNT";
    }
    function decimals() external pure returns (uint8){
        return 0;
    }

    function totalSupply() external view returns (uint){
        return count;
    }

    function balanceOf(address _dono) external view returns (uint balance){
        if (registros[_dono].horaCriado == 0){
            return 0;
        }
        else {
            return 1;
        }
    }

    function allowance(address _dono, address _gastador) external view returns (uint remaining){
        // Returns the amount which _spender is still allowed to withdraw from _owner.
        return permite_sacar[_dono][_gastador];
    }

    function transfer(address _para, uint _quantos) public returns (bool _sucesso){
        // Transfere a quantidade _valor de tokens para o endereço _para, e DEVE disparar o evento Transfer. A função DEVE lançar uma exceção se o saldo da conta do chamador da mensagem não tiver tokens suficientes para gastar.
        require(saldo_tokens[msg.sender] >= _quantos, "Nao ha saldo suficiente para transferir!");

        saldo_tokens[msg.sender] -= _quantos;
        adicionar_detentor(_para);
        saldo_tokens[_para]      += _quantos;

        emit Transfer(msg.sender, _para, _quantos);
        return true;
    }

    // Permite que _gastador saque da sua conta várias vezes, até a quantidade _valor. Se esta função for chamada novamente, ela sobrescreve a permissão atual com _valor.
    function approve(address _gastador, uint _quanto) external returns (bool _sucesso){
        permite_sacar[msg.sender][_gastador] = _quanto;

        emit Approval(msg.sender, _gastador, _quanto);

        return true;
    }

    function transferFrom(address _de, address _para, uint _quantos) public returns (bool _sucesso){
        require(saldo_tokens[_de] >= _quantos, "Nao ha saldo suficiente para transferir!");
        require(permite_sacar[_de][msg.sender] >= _quantos, "Nao tem permissao para retirar!");

        saldo_tokens[_de] = saldo_tokens[_de] - _quantos;
        adicionar_detentor(_para);
        saldo_tokens[_para] = saldo_tokens[_para] + _quantos;

        emit Transfer(_de, _para, _quantos);

        permite_sacar[_de][msg.sender] = permite_sacar[_de][msg.sender] - _quantos;

        return true;
    }




}


