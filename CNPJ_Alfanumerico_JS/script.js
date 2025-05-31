var _a;
var CNPJ = /** @class */ (function () {
    function CNPJ() {
    }
    CNPJ.isValid = function (cnpj) {
        if (!this.regexCaracteresNaoPermitidos.test(cnpj)) {
            var cnpjSemMascara = this.removeMascaraCNPJ(cnpj);
            if (this.regexCNPJ.test(cnpjSemMascara) && cnpjSemMascara !== CNPJ.cnpjZerado) {
                var dvInformado = cnpjSemMascara.substring(this.tamanhoCNPJSemDV);
                var dvCalculado = this.calculaDV(cnpjSemMascara.substring(0, this.tamanhoCNPJSemDV));
                return dvInformado === dvCalculado;
            }
        }
        return false;
    };
    CNPJ.calculaDV = function (cnpj) {
        if (!this.regexCaracteresNaoPermitidos.test(cnpj)) {
            var cnpjSemMascara = this.removeMascaraCNPJ(cnpj);
            if (this.regexCNPJSemDV.test(cnpjSemMascara) && cnpjSemMascara !== this.cnpjZerado.substring(0, this.tamanhoCNPJSemDV)) {
                var somatorioDV1 = 0;
                var somatorioDV2 = 0;
                for (var i = 0; i < this.tamanhoCNPJSemDV; i++) {
                    var asciiDigito = cnpjSemMascara.charCodeAt(i) - this.valorBase;
                    somatorioDV1 += asciiDigito * this.pesosDV[i + 1];
                    somatorioDV2 += asciiDigito * this.pesosDV[i];
                }
                var dv1 = somatorioDV1 % 11 < 2 ? 0 : 11 - (somatorioDV1 % 11);
                somatorioDV2 += dv1 * this.pesosDV[this.tamanhoCNPJSemDV];
                var dv2 = somatorioDV2 % 11 < 2 ? 0 : 11 - (somatorioDV2 % 11);
                return "".concat(dv1).concat(dv2);
            }
        }
        throw new Error("Não é possível calcular o DV pois o CNPJ fornecido é inválido");
    };
    CNPJ.removeMascaraCNPJ = function (cnpj) {
        return cnpj.replace(this.regexCaracteresMascara, "");
    };
    CNPJ.tamanhoCNPJSemDV = 12;
    CNPJ.regexCNPJSemDV = /^([A-Z\d]){12}$/;
    CNPJ.regexCNPJ = /^([A-Z\d]){12}(\d){2}$/;
    CNPJ.regexCaracteresMascara = /[./-]/g;
    CNPJ.regexCaracteresNaoPermitidos = /[^A-Z\d./-]/i;
    CNPJ.valorBase = "0".charCodeAt(0);
    CNPJ.pesosDV = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    CNPJ.cnpjZerado = "00000000000000";
    return CNPJ;
}());
// Função para validar e exibir o resultado na interface
(_a = document.getElementById("validateButton")) === null || _a === void 0 ? void 0 : _a.addEventListener("click", function () {
    var cnpjInput = document.getElementById("cnpjInput").value;
    var resultMessage = document.getElementById("resultMessage");
    if (CNPJ.isValid(cnpjInput)) {
        resultMessage.textContent = "CNPJ válido!";
        resultMessage.style.color = "green";
    }
    else {
        resultMessage.textContent = "CNPJ inválido!";
        resultMessage.style.color = "red";
    }
});
