# online-payment

## How to test

#### requirement
```
gem install rspec
gem install 'rspec-collection_matchers'
```

#### run tests
```
rspec bootstrap_spec.rb
```

## How to run
```
ruby bootstrap.rb
```

## Considerações
Poderia haver um agrupamento pelo tipo de item para que as notificações de email não fossem diversas vezes (por item), mas imaginei que fosse um overhead.
Poderia ter utilizado mais mocks e outras técnicas nos testes para validar se alguns métodos foram chamados (verifying)
