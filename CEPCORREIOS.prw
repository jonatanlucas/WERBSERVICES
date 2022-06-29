//Consome serviço de correios para preenchimento dos campos de endereço automaticamente no Protheus, através do CEP.

#INCLUDE "TOTVS.ch"  
#INCLUDE "XMLXFUN.CH"

User Function CEPCORREIOS()

//HttpPost( < cUrl >, [ cGetParms ], [ cPostParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderGet ] )
Local cUrlWSDL          := "https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente"
Local nTimeOut      := 120
Local aHeadStr      := {} 
Local cData         := ""
Local cHeadRet      := ""

//Capturar o retorno do WebService(rua, municipio, estado, etc)
Local aData         := {}

//Variveis da funo XmlParser( [ cXml ], [ cReplace ], [ cError ], [ cWarning ] )

Local oXml          := ""
Local cError        := ""
Local cWarning      := ""
Local sPostRet      := ""

DbSelectArea("SA1")

    //Se no tiver vazio, ele far a busca
    IF !Empty(M->A1_CEP)
        //Montamos o cabealho do SOAP
        aAdd(aHeadStr,'SOAPAction: "http://cliente.bean.master.sigep.bsb.correios.com.br/AtendeCliente/consultaCEP"')
        aAdd(aHeadStr,'Content-Type: text/xml;charset=UTF-8')

        cData+="<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:cli='http://cliente.bean.master.sigep.bsb.correios.com.br/'>"
        cData+="<soapenv:Header/>"
        cData+="<soapenv:Body>"
        cData+="<cli:consultaCEP>"
        cData+="<cep>"+M->A1_CEP+"</cep>"
        cData+="</cli:consultaCEP>"
        cData+="</soapenv:Body>"
        cData+="</soapenv:Envelope>"

                    //HttpPost( < cUrl >, [ cGetParms ], [ cPostParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderGet ] )
        sPostRet    := HttpPost(cUrlWSDL,   "",              cData,         nTimeOut,       aHeadStr,    @cHeadRet)

        //Utilizaremos o sPostRet para trabalharmos dentro da funo XMLParser

        IF !Empty(sPostRet)
            IF AT("<faultcode>",sPostRet) == 0
                //XmlParser( [ cXml ], [ cReplace ], [ cError ], [ cWarning ] )
                oXml := XmlParser(sPostRet,"_",@cError, @cWarning)

                aAdd(aData,oXml:_SOAP_ENVELOPE:_SOAP_BODY:_NS2_CONSULTACEPRESPONSE:_RETURN:_END:TEXT)    //[1]
                aAdd(aData,oXml:_SOAP_ENVELOPE:_SOAP_BODY:_NS2_CONSULTACEPRESPONSE:_RETURN:_BAIRRO:TEXT) //[2]
                aAdd(aData,oXml:_SOAP_ENVELOPE:_SOAP_BODY:_NS2_CONSULTACEPRESPONSE:_RETURN:_CIDADE:TEXT) //[3]
                aAdd(aData,oXml:_SOAP_ENVELOPE:_SOAP_BODY:_NS2_CONSULTACEPRESPONSE:_RETURN:_UF:TEXT)     //[4]
                aAdd(aData,oXml:_SOAP_ENVELOPE:_SOAP_BODY:_NS2_CONSULTACEPRESPONSE:_RETURN:_CEP:TEXT)    //[5]

                cEnd            := aData[1] 
                M->A1_BAIRRO    := aData[2]
                M->A1_MUN       := aData[3]
                M->A1_EST       := aData[4]
            ELSE
                Alert("CEP INVÁLIDO OU NÃO ENCONTRADO","ATENÇÃO")
            ENDIF
        ENDIF
    ENDIF
return cEnd
