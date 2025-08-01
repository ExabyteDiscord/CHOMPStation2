import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Button,
  Divider,
  Icon,
  Image,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';
import { capitalize } from 'tgui-core/string';

import { NoSpriteWarning } from '../components';
import { prepareSearch } from '../functions';
import type { Access, Target } from '../types';

export const ModifyRobotAccess = (props: {
  target: Target;
  tab_icon: string;
  all_access: Access[];
}) => {
  const { act } = useBackend();
  const { target, tab_icon, all_access } = props;
  const [searchAccessAll, setSearchAccessAll] = useState<string>('');
  const [searchAccessActive, setSearchAccessActive] = useState<string>('');

  return (
    <>
      {!target.active && <NoSpriteWarning name={target.name} />}
      <Stack fill>
        <Stack.Item width="30%">
          <AccessSection
            title="Add Access"
            searchText={searchAccessAll}
            onSearchText={setSearchAccessAll}
            access={all_access}
            action="add_access"
            buttonColor="green"
            buttonIcon="arrow-right-to-bracket"
          />
        </Stack.Item>
        <Stack.Item width="40%">
          <Image
            fixErrors
            src={tab_icon}
            style={{
              display: 'block',
              marginLeft: 'auto',
              marginRight: 'auto',
              width: '200px',
            }}
          />
          <Stack vertical>
            <Stack.Item>
              <Stack>
                <Stack.Item grow />
                <Stack.Item>
                  <Button
                    height="20px"
                    color="green"
                    icon="satellite"
                    onClick={() => act('add_station')}
                  >
                    Add station access
                  </Button>
                </Stack.Item>
                <Stack.Item grow />
                <Button
                  height="20px"
                  color="red"
                  icon="satellite"
                  onClick={() => act('rem_station')}
                >
                  Remove station access
                </Button>
                <Stack.Item grow />
              </Stack>
            </Stack.Item>
            <Stack.Item mt="40px">
              <Stack>
                <Stack.Item grow />
                <Button
                  height="20px"
                  color="green"
                  icon="building"
                  onClick={() => act('add_centcom')}
                >
                  Add centcom access
                </Button>
                <Stack.Item grow />
                <Button
                  height="20px"
                  color="red"
                  icon="building"
                  onClick={() => act('rem_centcom')}
                >
                  Remove centcom access
                </Button>
                <Stack.Item grow />
              </Stack>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item width="30%">
          <AccessSection
            title="Remove Access"
            searchText={searchAccessActive}
            onSearchText={setSearchAccessActive}
            access={target.active_access}
            action="rem_access"
            buttonColor="red"
            buttonIcon="trash"
          />
        </Stack.Item>
      </Stack>
    </>
  );
};

const AccessSection = (props: {
  title: string;
  searchText: string;
  onSearchText: React.Dispatch<React.SetStateAction<string>>;
  access: Access[];
  action: string;
  buttonColor: string;
  buttonIcon: string;
}) => {
  const { act } = useBackend();
  const {
    title,
    searchText,
    onSearchText,
    access,
    action,
    buttonColor,
    buttonIcon,
  } = props;
  return (
    <Section title={title} fill scrollable scrollableHorizontal>
      <Input
        fluid
        value={searchText}
        placeholder="Search for access..."
        onChange={(value: string) => onSearchText(value)}
      />
      <Divider />
      <Stack>
        <Stack.Item width="100%">
          {prepareSearch(access, searchText).map((acc, i) => {
            return (
              <Button
                fluid
                key={i}
                onClick={() =>
                  act(action, {
                    access: acc.id,
                  })
                }
              >
                <Stack fill align="center">
                  <Stack.Item grow overflow="hidden">
                    {capitalize(acc.name)}
                  </Stack.Item>
                  <Stack.Item>
                    <Icon
                      name={buttonIcon}
                      backgroundColor={buttonColor}
                      size={1.5}
                    />
                  </Stack.Item>
                </Stack>
              </Button>
            );
          })}
        </Stack.Item>
      </Stack>
    </Section>
  );
};
