
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = """
---
name: az_keyvault
author:
    - Henrik Gerdes (@hegerdes) <hegerdes@outlook.de>
version_added: '1.12.0'
requirements:
    - azure-keyvault
    - azure-identity
short_description: Read secret from Azure Key Vault.
description:
  - This lookup returns the content of secret saved in Azure Key Vault.
  - When ansible host is MSI enabled Azure VM, user don't need provide any credential to access to Azure Key Vault.
options:
    _terms:
        description: Secret name, version can be included like secret_name/secret_version.
        required: True
    vault_url:
        description: Url of Azure Key Vault.
        required: True
    vault_object:
        description: Secret, Key or Cert
        required: False

notes:
    - If version is not provided, this plugin will return the latest version of the secret.
    - If ansible is running on Azure Virtual Machine with MSI enabled, client_id, secret and tenant isn't required.
    - For enabling MSI on Azure VM, please refer to this doc https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/
    - After enabling MSI on Azure VM, remember to grant access of the Key Vault to the VM by adding a new Acess Policy in Azure Portal.
    - If MSI is not enabled on ansible host, it's required to provide a valid service principal which has access to the key vault.
    - To use a plugin from a collection, please reference the full namespace, collection name, and lookup plugin name that you want to use.
"""

EXAMPLE = """
- name: Look up secret when ansible host is MSI enabled Azure VM
  debug:
    msg: "the value of this secret is {{
        lookup(
          'azure.azcollection.azure_keyvault_secret',
          'testSecret/version',
          vault_url='https://yourvault.vault.azure.net'
        )
      }}"
"""

RETURN = """
  _raw:
    description: secret content string
"""

from ansible.plugins.lookup import LookupBase
from ansible.utils.display import Display
from azure.identity import ManagedIdentityCredential, VisualStudioCodeCredential, AzureCliCredential, ChainedTokenCredential
from azure.keyvault.secrets import SecretClient
from azure.keyvault.keys import KeyClient
from jwcrypto.jwk import JWK

import json
display = Display()

class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):

        miCredential = ManagedIdentityCredential()
        azCredential = AzureCliCredential()
        vsCredential = VisualStudioCodeCredential()
        azCreds = ChainedTokenCredential(azCredential, miCredential, vsCredential)


        # First of all populate options,
        # this will already take into account env vars and ini config
        self.set_options(var_options=variables, direct=kwargs)


        vault_url = kwargs.pop('vault_url', None)
        keyvaultType = kwargs.pop('vault_object', "secret")
        keyvaultPvtKey = kwargs.pop('private_key', False)
        azSecClient = SecretClient(vault_url=vault_url, credential=azCreds)
        azKeyClient = KeyClient(vault_url=vault_url, credential=azCreds)

        # lookups in general are expected to both take a list as input and output a list
        # this is done so they work with the looping construct 'with_'.
        ret = []

        for term in terms:
            display.debug("Getting secret: %s" % term)
            if keyvaultType == "secret":
                    ret.append(azSecClient.get_secret(term).value)
            elif keyvaultType == "key":
                    az_key = azKeyClient.get_key(term).key
                    az_jwk = JWK.from_json(json.dumps(az_key._to_generated_model().serialize()))
                    ret.append(az_jwk.export_to_pem(private_key=keyvaultPvtKey).decode("utf-8"))
            else:
                    raise NotImplemented("Unsupported KeyVault Type")
            # match keyvaultType:
            #     case "secret":
            #         ret.append(azSecClient.get_secret(term).value)
            #     case "key":
            #         ret.append(azKeyClient.get_key(term).key)
            #     case _:
            #         raise NotImplemented("Unsupported KeyVault Type")

        return ret
