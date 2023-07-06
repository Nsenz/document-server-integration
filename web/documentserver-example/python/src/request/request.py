#
# (c) Copyright Ascensio System SIA 2023
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from dataclasses import dataclass
from re import sub
from typing import Optional
from urllib.parse import ParseResult
from django.http import HttpRequest
from src.configuration import ConfigurationManager

@dataclass
class RequestManager():
    config_manager: ConfigurationManager
    request: HttpRequest

    def base_url(self) -> ParseResult:
        return self.config_manager.example_url() or self.__base_url()

    def __base_url(self):
        return ParseResult(
            scheme=self.__scheme(),
            netloc=self.request.get_host(),
            path='',
            params='',
            query='',
            fragment=''
        )

    def __scheme(self) -> str:
        return (
            self.request.headers.get('X-Forwarded-Proto') or
            self.request.scheme or
            'http'
        )

    def resolve_user_host(self, user_host: Optional[str]) -> str:
        host = user_host or self.__remote_address()
        return sub(r'[^0-9\-.a-zA-Z_=]', '_', host)

    def __remote_address(self) -> str:
        forwarded = self.request.headers.get('X-Forwarded-For')
        if forwarded:
            return forwarded.split(',')[0]
        return self.request.META['REMOTE_ADDR']
